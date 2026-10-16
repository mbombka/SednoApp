using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;

namespace Sedno.Infrastructure;

public static class ModelRegistration
{
    public static IServiceCollection AddSednoModel(this IServiceCollection services,
        IConfiguration configuration, bool isDevelopment)
    {
        switch (configuration["Model:Provider"] ?? "disabled")
        {
            case "mock" when isDevelopment:
                services.AddScoped<IModelProvider, DevelopmentMockProvider>();
                break;
            case "mock":
                throw new InvalidOperationException("Development mock cannot run outside Development.");
            case "disabled":
                services.AddScoped<IModelProvider, DisabledModelProvider>();
                break;
            case "openai":
                var options = configuration.GetSection("Model:OpenAI").Get<OpenAiModelOptions>() ?? new();
                options.ApiKey = configuration["OpenAI:ApiKey"] ?? "";
                options.Validate();
                services.AddSingleton(options);
                services.AddHttpClient("openai-model", client => client.Timeout = Timeout.InfiniteTimeSpan)
                    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
                    .RemoveAllLoggers();
                services.AddScoped<IModelProvider>(sp => new OpenAiModelProvider(
                    sp.GetRequiredService<IHttpClientFactory>().CreateClient("openai-model"), options,
                    sp.GetRequiredService<TimeProvider>(), sp.GetService<SimplificationTimings>()));
                break;
            default:
                throw new InvalidOperationException("Unsupported model provider.");
        }
        return services;
    }
}
