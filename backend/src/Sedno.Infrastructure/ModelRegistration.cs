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
                options.Validate();
                services.AddSingleton(options);
                services.AddHttpClient("openai-model", client => client.Timeout = Timeout.InfiniteTimeSpan)
                    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
                    .RemoveAllLoggers();
                services.AddScoped<IModelProvider>(sp => new OpenAiModelProvider(
                    sp.GetRequiredService<IHttpClientFactory>().CreateClient("openai-model"), options,
                    sp.GetRequiredService<TimeProvider>()));
                break;
            case "openai-agent":
                var agentOptions = configuration.GetSection("OpenAI").Get<OpenAiAgentOptions>() ?? new();
                agentOptions.Validate();
                services.AddSingleton(agentOptions);
                services.AddSingleton<AgentSessionCleanupWorker>();
                services.AddSingleton<IAgentSessionCleanupQueue>(sp => sp.GetRequiredService<AgentSessionCleanupWorker>());
                services.AddHostedService(sp => sp.GetRequiredService<AgentSessionCleanupWorker>());
                services.AddHttpClient("openai-agent", client => client.Timeout = Timeout.InfiniteTimeSpan)
                    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
                    .RemoveAllLoggers();
                services.AddScoped<IModelProvider>(sp => new OpenAiAgentProvider(
                    sp.GetRequiredService<IHttpClientFactory>().CreateClient("openai-agent"), agentOptions,
                    sp.GetRequiredService<TimeProvider>(),
                    sp.GetRequiredService<Microsoft.Extensions.Logging.ILogger<OpenAiAgentProvider>>(),
                    sp.GetRequiredService<IAgentSessionCleanupQueue>()));
                break;
            default:
                throw new InvalidOperationException("Unsupported model provider.");
        }
        return services;
    }
}
