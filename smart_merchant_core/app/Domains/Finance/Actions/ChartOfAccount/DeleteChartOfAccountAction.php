<?php

namespace App\Domains\Finance\Actions\ChartOfAccount;

use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteChartOfAccountAction
{
    public function __construct(private readonly ChartOfAccountRepositoryInterface $repository) {}

    public function handle(string $accountId, string $businessId): bool
    {
        $account = $this->repository->findById($accountId);

        if (!$account || $account->business_id !== $businessId) {
            throw new ModelNotFoundException("Account not found.");
        }

        if ($account->is_system) {
            throw ValidationException::withMessages(['id' => 'Cannot delete a system root account.']);
        }

        if ($this->repository->countChildren($account->id) > 0) {
            throw ValidationException::withMessages(['id' => 'Cannot delete an account that has sub-accounts.']);
        }

        if ($this->repository->hasJournalLines($account->id)) {
            throw ValidationException::withMessages(['id' => 'Cannot delete an account that is associated with journal entries.']);
        }

        return $this->repository->delete($account);
    }
}
