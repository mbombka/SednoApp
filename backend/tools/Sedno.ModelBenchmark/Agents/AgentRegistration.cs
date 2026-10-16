using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
namespace Sedno.ModelBenchmark.Agents;
public static class AgentRegistration
{
 public static IServiceCollection AddBenchmarkAgent(this IServiceCollection services, IConfiguration configuration)
 {
                var agentOptions = configuration.GetSection("OpenAI").Get<OpenAiAgentOptions>() ?? new();
                agentOptions.Validate();
                services.AddSingleton(agentOptions);
                services.AddSingleton<AgentStreamRunner>();
                services.AddSingleton<AgentSessionCleanupWorker>();
                services.AddSingleton<IAgentSessionCleanupQueue>(sp => sp.GetRequiredService<AgentSessionCleanupWorker>());
                services.AddHostedService(sp => sp.GetRequiredService<AgentSessionCleanupWorker>());
                services.AddHostedService(sp => sp.GetRequiredService<AgentStreamRunner>());
                services.AddHttpClient("openai-agent", client => client.Timeout = Timeout.InfiniteTimeSpan)
                    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
                    .RemoveAllLoggers();
                services.AddScoped<IModelProvider>(sp => new OpenAiAgentProvider(
                    sp.GetRequiredService<IHttpClientFactory>().CreateClient("openai-agent"), agentOptions,
                    sp.GetRequiredService<TimeProvider>(),
                    sp.GetRequiredService<Microsoft.Extensions.Logging.ILogger<OpenAiAgentProvider>>(),
                    sp.GetRequiredService<IAgentSessionCleanupQueue>(), sp.GetRequiredService<AgentStreamRunner>()));

 return services;
 }
}
