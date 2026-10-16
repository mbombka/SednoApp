using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace Sedno.Application;

public sealed class InputValidationException(string code, string message) : Exception(message)
{
    public string Code { get; } = code;
}

public sealed class SimplificationService(IUsageStore usage, IModelProvider model, TimeProvider clock, byte[] fingerprintKey)
{
    public static void Validate(SimplificationInput input)
    {
        if (string.IsNullOrWhiteSpace(input.RequestId) || input.RequestId.Length > 100 ||
            input.RequestId.Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '-' or '_')))
            throw new InputValidationException("invalid_request_id", "Nieprawidłowy identyfikator żądania.");
        if (string.IsNullOrWhiteSpace(input.Text))
            throw new InputValidationException("empty_text", "Wpisz tekst do uproszczenia.");
        if (new StringInfo(input.Text).LengthInTextElements > 4000)
            throw new InputValidationException("text_too_long", "Tekst może mieć maksymalnie 4000 znaków.");
    }

    public async Task<(string Kind, SimplificationResponseDto? Response, QuotaDto Quota)> RunAsync(
        Guid identityId, SimplificationInput input, CancellationToken cancellationToken)
    {
        Validate(input);
        var fingerprint = Convert.ToHexString(HMACSHA256.HashData(fingerprintKey, Encoding.UTF8.GetBytes(input.Text)));
        var reservation = await usage.ReserveAsync(identityId, input.RequestId, fingerprint, cancellationToken);
        if (reservation.Kind != "reserved") return (reservation.Kind, null, reservation.Quota);
        string output;
        try { output = await model.SimplifyAsync(input.Text, cancellationToken); }
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
        if (!await usage.CompleteAsync(identityId, input.RequestId, cancellationToken))
            return ("expired", null, await usage.GetQuotaAsync(identityId, cancellationToken));
        var quota = await usage.GetQuotaAsync(identityId, cancellationToken);
        return ("succeeded", new(new(input.RequestId, output, clock.GetUtcNow()), quota), quota);
    }
}
