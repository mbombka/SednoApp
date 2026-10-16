using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Sedno.Application;
using Sedno.Infrastructure;
using Sedno.ModelBenchmark.Agents;

if (!args.Contains("--live"))
{
    Console.WriteLine("Test wykonuje płatne wywołania API na tekstach syntetycznych. Uruchom z --live [--agent | --cleanup-agent] [--rounds 5] [--model gpt-6-luna] [--effort none] [--prompt plik] [--text-report plik.md].");
    return 0;
}

string Option(string name, string fallback)
{
    var index = Array.IndexOf(args, name);
    if (index < 0) return fallback;
    if (index + 1 >= args.Length || args[index + 1].StartsWith("--")) throw new ArgumentException();
    return args[index + 1];
}

try
{
    var allowedFlags = new[] { "--live", "--agent", "--rounds", "--model", "--effort", "--prompt", "--text-report", "--cleanup-agent" };
    for (var i = 0; i < args.Length; i++)
    {
        if (!allowedFlags.Contains(args[i])) throw new ArgumentException();
        if (args[i] is not ("--live" or "--agent" or "--cleanup-agent")) i++;
    }
    var useAgent = args.Contains("--agent") || args.Contains("--cleanup-agent");
    var rounds = int.Parse(Option("--rounds", "5"));
    if (rounds is < 1 or > 20) throw new ArgumentException();
    var model = Option("--model", "gpt-6-luna");
    var effort = Option("--effort", "none");
    if (model.Length > 100 || !model.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '.') ||
        effort is not ("none" or "minimal" or "low" or "medium" or "high" or "xhigh")) throw new ArgumentException();
    var reportPath = Option("--text-report", "");
    var textRows = new StringBuilder();
    var reportSummary = new StringBuilder();
    var startedAt = DateTimeOffset.UtcNow;
    // Explicit opt-in export of the built-in synthetic fixtures, never application traffic.
    static string Cell(string text) => System.Net.WebUtility.HtmlEncode(text)
        .Replace("|", "&#124;").Replace("\\", "&#92;").Replace("`", "&#96;")
        .Replace("[", "&#91;").Replace("]", "&#93;").Replace("*", "&#42;")
        .Replace("_", "&#95;").Replace("\r\n", "\n").Replace("\r", "\n").Replace("\n", "<br>");
    if (reportPath.Length > 0)
    {
        // Check access before any paid calls. Existing report content is preserved.
        using var check = new FileStream(reportPath, FileMode.Append, FileAccess.Write);
    }
    var promptPath = Option("--prompt", "");
    var prompt = promptPath.Length == 0 ? SimplificationPrompt.Text : await File.ReadAllTextAsync(promptPath);
    if (string.IsNullOrWhiteSpace(prompt) || prompt.Length > 32000) throw new ArgumentException();
    var config = new ConfigurationBuilder().AddUserSecrets("sedno-backend-dev")
        .AddUserSecrets("sedno-model-benchmark")
        .AddEnvironmentVariables().Build();
    var key = config["OpenAI:ApiKey"];
    if (string.IsNullOrWhiteSpace(key) || key.Any(char.IsWhiteSpace))
    {
        Console.Error.WriteLine("Brak klucza: ustaw OpenAI__ApiKey albo sekret OpenAI:ApiKey (sedno-backend-dev).");
        return 2;
    }
    using var cancellation = new CancellationTokenSource();
    Console.CancelKeyPress += (_, e) => { e.Cancel = true; cancellation.Cancel(); };
    using var client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false }) { Timeout = Timeout.InfiniteTimeSpan };
    var variants = new List<(string Name, IModelProvider Provider)>
    {
        ("responses-default", new ResponsesClient(client, key, model, prompt, effort, "default")),
        ("responses-fast", new ResponsesClient(client, key, model, prompt, effort, "fast"))
    };
    using var host = Host.CreateDefaultBuilder(Array.Empty<string>()).ConfigureLogging(logging => logging.ClearProviders())
        .ConfigureServices(services =>
        {
            if (!useAgent) return;
            services.AddSingleton(TimeProvider.System);
            var agentConfig = new ConfigurationBuilder().AddConfiguration(config).AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["OpenAI:ApiKey"] = key,
                ["OpenAI:TimeoutSeconds"] = "8"
            }).Build();
            services.AddBenchmarkAgent(agentConfig);
        }).Build();
    await host.StartAsync(cancellation.Token);
    if (args.Contains("--cleanup-agent"))
    {
        var cleanup = host.Services.GetRequiredService<AgentSessionCleanupWorker>();
        var deadline = Stopwatch.StartNew();
        while (cleanup.AnySessionOpened && deadline.Elapsed < TimeSpan.FromSeconds(55))
            await Task.Delay(250, cancellation.Token);
        var complete = !cleanup.AnySessionOpened;
        using var stop = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        await host.StopAsync(stop.Token);
        Console.WriteLine(complete ? "Sprzątanie sesji agenta zakończone." : "Nie potwierdzono sprzątania. Ponów --live --cleanup-agent.");
        return complete ? 0 : 1;
    }
    using var scope = host.Services.CreateScope();
    if (useAgent) variants.Add(("agent", scope.ServiceProvider.GetRequiredService<IModelProvider>()));
    var texts = new[]
    {
        "Wniosek należy złożyć do 31 grudnia 2026 roku. Opłata wynosi 12,50 zł. Osoby poniżej 18 lat nie mogą złożyć wniosku samodzielnie.",
        string.Join(" ", Enumerable.Repeat("W przypadku niedostarczenia wymaganych dokumentów w terminie 14 dni od otrzymania wezwania wniosek pozostanie bez rozpatrzenia. Można zwrócić się o przedłużenie terminu, ale zgoda nie jest automatyczna.", 5)),
        string.Join(" ", Enumerable.Repeat("Uczestnik może zrezygnować z zajęć bez opłaty do 15 listopada 2026 roku. Po tej dacie zwrot 120 zł jest możliwy wyłącznie po przedstawieniu zaświadczenia. Rezygnację należy przesłać pisemnie do organizatora.", 19))
    };
    foreach (var text in texts) SimplificationService.Validate(new("benchmark", text));
    Console.WriteLine(JsonSerializer.Serialize(new
    {
        rodzaj = "konfiguracja",
        model,
        effort,
        rounds,
        limitSekund = 8,
        promptSha256 = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(prompt))),
        uwaga = "Model i prompt agenta wymagają zgodności z wariantem Responses. Wyniki nie oceniają jakości tekstu."
    }));
    var results = new List<(string Variant, double Ms, bool Ok)>();
    var failed = false;
    try
    {
        // Warm each variant once, then rotate order to reduce order/cache/network bias.
        for (var round = -1; round < rounds; round++)
            for (var sample = 0; sample < (round < 0 ? 1 : texts.Length); sample++)
                for (var step = 0; step < variants.Count; step++)
                {
                    var (name, provider) = variants[(step + Math.Max(round, 0) + sample) % variants.Count];
                    var timer = Stopwatch.StartNew();
                    var status = "ok";
                    string? output = null;
                    try { output = await provider.SimplifyAsync(texts[sample], cancellation.Token); }
                    catch (SimplificationTimeoutException) { status = "timeout"; }
                    catch (ModelProviderException) { status = "blad_api"; }
                    timer.Stop();
                    if (reportPath.Length > 0)
                        textRows.AppendLine($"| {(round < 0 ? "Rozgrzewka" : $"Runda {round + 1}")} | {sample + 1} | {name} | {status} | {timer.Elapsed.TotalSeconds.ToString("F3", System.Globalization.CultureInfo.InvariantCulture)} | {Cell(texts[sample])} | {Cell(output ?? "Brak wyniku — żądanie nie zakończyło się poprawnie.")} |");
                    var probe = provider as ResponsesClient;
                    Console.WriteLine(JsonSerializer.Serialize(new
                    {
                        rodzaj = round < 0 ? "rozgrzewka" : "pomiar",
                        wariant = name,
                        runda = round + 1,
                        probka = sample + 1,
                        status,
                        ms = timer.Elapsed.TotalMilliseconds,
                        znakiWejscia = texts[sample].Length,
                        znakiWyniku = output?.Length ?? 0,
                        http = probe?.HttpStatus,
                        trybOtrzymany = probe?.ServedTier,
                        tokenyWejscia = probe?.InputTokens,
                        tokenyWyjscia = probe?.OutputTokens
                    }));
                    if (round >= 0) results.Add((name, timer.Elapsed.TotalMilliseconds, status == "ok"));
                    failed |= status != "ok";
                }
        foreach (var group in results.GroupBy(r => r.Variant))
        {
            var times = group.Where(r => r.Ok).Select(r => r.Ms).Order().ToArray();
            if (reportPath.Length > 0)
            {
                var median = times.Length == 0 ? "—" : ((times[(times.Length - 1) / 2] + times[times.Length / 2]) / 2000).ToString("F3", System.Globalization.CultureInfo.InvariantCulture);
                reportSummary.AppendLine($"| {group.Key} | {median} | {times.Length}/{group.Count()} | {group.Count(r => !r.Ok)} |");
            }
            Console.WriteLine(JsonSerializer.Serialize(new
            {
                rodzaj = "podsumowanie",
                wariant = group.Key,
                proby = group.Count(),
                sukcesy = times.Length,
                bledy = group.Count(r => !r.Ok),
                medianaMs = times.Length == 0 ? (double?)null : (times[(times.Length - 1) / 2] + times[times.Length / 2]) / 2,
                p95Ms = times.Length == 0 ? (double?)null : times[(int)Math.Ceiling(times.Length * .95) - 1]
            }));
        }
    }
    finally
    {
        // Give detached agent streams and the existing cleanup worker time to delete sessions.
        if (useAgent)
        {
            var cleanup = host.Services.GetRequiredService<AgentSessionCleanupWorker>();
            var deadline = Stopwatch.StartNew();
            while (cleanup.AnySessionOpened && deadline.Elapsed < TimeSpan.FromSeconds(30))
                await Task.Delay(250);
            if (cleanup.AnySessionOpened)
            {
                Console.Error.WriteLine("Nie potwierdzono usunięcia wszystkich sesji. Uruchom benchmark z --live --cleanup-agent, aby ponowić sprzątanie.");
                failed = true;
            }
        }
        using var stop = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        await host.StopAsync(stop.Token);
    }
    if (reportPath.Length > 0)
    {
        var report = $"\n\n## Powtórny pomiar z zapisem tekstów — {startedAt:yyyy-MM-dd HH:mm:ss} UTC\n\n" +
            $"Model: `{model}`, reasoning: `{effort}`. Rundy: {rounds}. Limit: 8 s.\n\n" +
            $"SHA-256 promptu: `{Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(prompt)))}`.\n\n" +
            "Teksty syntetyczne i odpowiedzi zapisano na wyraźne życzenie użytkownika. " +
            "To nowa seria; wcześniejsze wyniki powyżej dotyczą poprzedniego pomiaru. " +
            "Mediana obejmuje wyłącznie udane pomiary, bez rozgrzewki.\n\n" +
            "| Wariant | Mediana [s] | Sukcesy | Błędy/timeouty |\n|---|---:|---:|---:|\n" + reportSummary +
            "\n### Pełne teksty wejściowe i wynikowe\n\n" +
            "Tabela zawiera wszystkie wywołania, w tym rozgrzewkę. Zachowano pełne teksty, " +
            "łącznie z powtórzeniami w dłuższych wejściach. Odpowiedzi nie były redagowane; " +
            "podziały wierszy przedstawiono jako przełamania linii w komórkach.\n\n" +
            "| Etap | Próbka | Wariant | Status | Czas [s] | Tekst wejściowy | Tekst wynikowy |\n" +
            "|---|---:|---|---|---:|---|---|\n" + textRows;
        await File.AppendAllTextAsync(reportPath, report);
    }
    return failed ? 1 : 0;
}
catch (OperationCanceledException)
{
    Console.Error.WriteLine("Test został przerwany.");
    return 130;
}
catch (Exception)
{
    // Do not print exceptions: configuration, paths or upstream bodies may contain secrets.
    Console.Error.WriteLine("Nie udało się uruchomić testu. Sprawdź argumenty, plik promptu i konfigurację agenta.");
    return 2;
}
