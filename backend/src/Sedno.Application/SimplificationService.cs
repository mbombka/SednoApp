using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace Sedno.Application;

public sealed class InputValidationException(string code, string message) : Exception(message)
{
    public string Code { get; } = code;
}

public sealed class SimplificationService(IUsageStore usage, IModelProvider model, TimeProvider clock, byte[] fingerprintKey, SimplificationTimings? timings = null)
{
    public static void Validate(SimplificationInput input)
    {
        if (string.IsNullOrWhiteSpace(input.RequestId) || input.RequestId.Length > 100 ||
            input.RequestId.Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '-' or '_')))
            throw new InputValidationException("invalid_request_id", "Nieprawidłowy identyfikator żądania.");
        if (input.Mode is not ("simplify" or "correct"))
            throw new InputValidationException("invalid_mode", "Nieprawidłowy tryb tekstu.");
        if (input.Language is not ("pl" or "en"))
            throw new InputValidationException("invalid_language", "Unsupported text language.");
        if (string.IsNullOrWhiteSpace(input.Text))
            throw new InputValidationException("empty_text", "Wpisz tekst.");
        if (new StringInfo(input.Text).LengthInTextElements > 4000)
            throw new InputValidationException("text_too_long", "Tekst może mieć maksymalnie 4000 znaków.");
    }

    public async Task<(string Kind, SimplificationResponseDto? Response, QuotaDto Quota)> RunAsync(
        Guid identityId, SimplificationInput input, CancellationToken cancellationToken)
    {
        Validate(input);
        // Preserve legacy simplify fingerprints; separate correction keys by purpose.
        var modeKey = input.Mode == "correct"
            ? HMACSHA256.HashData(fingerprintKey, "sedno.correct.v1"u8)
            : fingerprintKey;
        // Keep existing Polish fingerprints, bind every other language to the key.
        if (input.Language != "pl")
            modeKey = HMACSHA256.HashData(modeKey, Encoding.UTF8.GetBytes($"sedno.language.v1:{input.Language}"));
        var fingerprint = Convert.ToHexString(HMACSHA256.HashData(modeKey, Encoding.UTF8.GetBytes(input.Text)));
        ReservationOutcome reservation;
        using (timings?.Measure(SimplificationStage.Reservation))
            reservation = await usage.ReserveAsync(identityId, input.RequestId, fingerprint, cancellationToken);
        if (reservation.Kind != "reserved") return (reservation.Kind, null, reservation.Quota);
        string output;
        try
        {
            using (timings?.Measure(SimplificationStage.Model))
                output = input.Mode == "correct"
                    ? await model.CorrectAsync(input.Text, input.Language, cancellationToken)
                    : await model.SimplifyAsync(input.Text, input.Language, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            // A client disconnect does not prove the provider failed. The reservation expires later.
            throw;
        }
        catch (SimplificationTimeoutException)
        {
            await usage.FailAsync(identityId, input.RequestId, cancellationToken);
            return ("timeout", null, await usage.GetQuotaAsync(identityId, cancellationToken));
        }
        catch
        {
            await usage.FailAsync(identityId, input.RequestId, CancellationToken.None);
            return ("provider_failed", null, await usage.GetQuotaAsync(identityId, CancellationToken.None));
        }
        bool completed;
        using (timings?.Measure(SimplificationStage.Completion))
            completed = await usage.CompleteAsync(identityId, input.RequestId, cancellationToken);
        if (!completed)
            return ("expired", null, await usage.GetQuotaAsync(identityId, cancellationToken));
        QuotaDto quota;
        using (timings?.Measure(SimplificationStage.QuotaRead))
            quota = await usage.GetQuotaAsync(identityId, cancellationToken);
        return ("succeeded", new(new(input.RequestId, output, clock.GetUtcNow(), input.Mode, input.Language), quota), quota);
    }
}
