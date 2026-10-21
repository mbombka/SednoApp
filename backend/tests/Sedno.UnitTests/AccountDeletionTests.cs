using System.Net;
using System.Text.Json;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class AccountDeletionTests
{
    private sealed class Tokens : IPlayAccessTokenSource
    {
        public Task<string> GetAsync(CancellationToken ct) => Task.FromResult("server-access-token");
    }
    private sealed class Handler(Func<HttpRequestMessage, Task<HttpResponseMessage>> send) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) => send(request);
    }
    [Theory]
    [InlineData(HttpStatusCode.OK, "{}", true)]
    [InlineData(HttpStatusCode.BadRequest, "{\"error\":{\"message\":\"USER_NOT_FOUND\"}}", true)]
    [InlineData(HttpStatusCode.Forbidden, "{}", false)]
    [InlineData(HttpStatusCode.ServiceUnavailable, "{}", false)]
    public async Task ProviderDeletesOnlyServerSelectedUidAndFailsClosed(HttpStatusCode code, string body, bool success)
    {
        using var client = new HttpClient(new Handler(async request =>
        {
            Assert.Equal("https://identitytoolkit.googleapis.com/v1/projects/project/accounts:delete", request.RequestUri!.ToString());
            Assert.Equal("server-access-token", request.Headers.Authorization!.Parameter);
            using var json = JsonDocument.Parse(await request.Content!.ReadAsStringAsync());
            Assert.Equal("owner-uid", json.RootElement.GetProperty("localId").GetString());
            return new(code) { Content = new StringContent(body) };
        }));
        var service = new FirebaseAccountDeletion(client, new Tokens(), "project");
        if (success) await service.DeleteAsync("owner-uid", default);
        else await Assert.ThrowsAsync<InvalidOperationException>(() => service.DeleteAsync("owner-uid", default));
    }

    [Theory]
    [InlineData("{}", false)]
    [InlineData("{\"users\":[{\"localId\":\"owner\",\"disabled\":true}]}", false)]
    [InlineData("{\"users\":[{\"localId\":\"owner\"}]}", true)]
    public async Task LinkingRejectsDeletedOrDisabledFirebaseIdentity(string body, bool exists)
    {
        using var client = new HttpClient(new Handler(_ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(body) })));
        Assert.Equal(exists, (await new FirebaseAccountDeletion(client, new Tokens(), "project").GetStatusAsync("owner", default)).Enabled);
    }
    [Fact]
    public async Task LookupReadsFirebaseRevocationBoundaryAndDoesNotUseOtherUsersStatus()
    {
        using var client = new HttpClient(new Handler(_ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("{\"users\":[{\"localId\":\"other\",\"validSince\":\"0\"},{\"localId\":\"owner\",\"validSince\":\"12345\"}]}")
        })));
        var status = await new FirebaseAccountDeletion(client, new Tokens(), "project").GetStatusAsync("owner", default);
        Assert.True(status.Enabled);
        Assert.Equal(12345, status.ValidSince);
        Assert.False(status.Allows(12344));
        Assert.True(status.Allows(12345));
    }

}
