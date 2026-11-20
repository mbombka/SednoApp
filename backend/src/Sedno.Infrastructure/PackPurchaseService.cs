using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class PackPurchaseService(FirestoreStore db, IPlayPackClient play, TimeProvider clock)
{
    private const int UsesPerPack = 1000;

    public async Task<PackPurchaseDto> VerifyAsync(Guid accountId, string token, CancellationToken ct)
    {
        await using var lease = await LockAsync(accountId, ct);
        var purchase = await play.GetPackAsync(token, ct);
        if (purchase.ProductId != IPlayPackClient.ProductId ||
            purchase.AccountBinding != SubscriptionService.Binding(accountId))
            return new("invalid");
        return await ApplyAsync(accountId, token, purchase, lease, ct);
    }

    public async Task NotifyAsync(string token, bool fullRefund, CancellationToken ct)
    {
        var reference = db.PackPurchases.Document(FirestoreStore.Hash(token));
        var receipt = await db.GetAsync<PlayPackPurchase>(reference, ct);
        if (receipt is null && fullRefund)
        {
            // A refund can arrive before verification commits. Record it even if
            // Google has already stopped returning the purchase details.
            await db.Database.RunTransactionAsync(async transaction =>
            {
                if (await db.GetAsync<PlayPackPurchase>(transaction, reference, ct) is null)
                    db.Put(transaction, reference, new PlayPackPurchase { Revoked = true });
            }, cancellationToken: ct);
            receipt = await db.GetAsync<PlayPackPurchase>(reference, ct);
        }
        if (receipt?.Revoked == true) return;
        if (receipt is not null && fullRefund)
        {
            await using var lease = await LockAsync(receipt.AccountId, ct);
            await ApplyAsync(receipt.AccountId, token, new("CANCELLED", null, null, 0, false), lease, ct);
            return;
        }

        var purchase = await play.GetPackAsync(token, ct);
        if (purchase.ProductId != IPlayPackClient.ProductId || purchase.AccountBinding is null) return;
        var pointer = await db.GetAsync<AccountPointer>(db.Bindings.Document(purchase.AccountBinding), ct);
        if (pointer is not null) await VerifyAsync(pointer.AccountId, token, ct);
    }

    private Task<FirestoreLease> LockAsync(Guid accountId, CancellationToken ct) =>
        FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);

    private async Task<PackPurchaseDto> ApplyAsync(Guid accountId, string token, PlayPack purchase, FirestoreLease lease, CancellationToken ct)
    {
        if (purchase.State == "PENDING") return new("pending");
        if (purchase.State is not ("PURCHASED" or "CANCELLED") ||
            purchase.Quantity < 0 || purchase.Quantity > int.MaxValue / UsesPerPack) return new("invalid");

        var hash = FirestoreStore.Hash(token);
        var accountReference = db.Accounts.Document(FirestoreStore.Id(accountId));
        var receiptReference = db.PackPurchases.Document(hash);
        var accepted = await db.Database.RunTransactionAsync(async transaction =>
        {
            await lease.CheckAsync(transaction, ct);
            var account = await db.GetAsync<VerifiedAccount>(transaction, accountReference, ct);
            var receipt = await db.GetAsync<PlayPackPurchase>(transaction, receiptReference, ct);
            if (account is null || account.Deleting || receipt?.Revoked == true ||
                (receipt is not null && receipt.AccountId != accountId)) return false;

            var quantity = purchase.State == "PURCHASED" ? purchase.Quantity : 0;
            if (receipt is null && quantity > 0 && purchase.Consumed) return false;
            // A stale Play snapshot must never undo an earlier refund.
            if (receipt is not null && receipt.Quantity == quantity) return quantity > 0;
            if (receipt is not null && receipt.Quantity < quantity) return receipt.Quantity > 0;

            var credits = receipt is null ? quantity * UsesPerPack :
                account.PackCredits.GetValueOrDefault(hash) - (receipt.Quantity - quantity) * UsesPerPack;
            if (credits > 0) account.PackCredits[hash] = credits;
            else account.PackCredits.Remove(hash);
            db.Put(transaction, accountReference, account);
            db.Put(transaction, receiptReference, new PlayPackPurchase
            {
                AccountId = accountId, Quantity = quantity, Revoked = quantity == 0
            });
            return quantity > 0;
        }, cancellationToken: ct);

        // Commit before consuming at Play. Either receipt delivery path can retry
        // this call after a transient failure without topping up the account again.
        if (accepted && !purchase.Consumed) await play.ConsumePackAsync(token, ct);
        return new(accepted ? "credited" : "invalid");
    }
}
