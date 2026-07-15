<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Models\Core\Account;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\DTOs\AccountListCriteriaDTO;
use App\Domains\Core\DTOs\AccountSearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateAccountDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AccountEloquentRepository implements AccountRepositoryInterface
{
    public function create(array $data): Account
    {
        return Account::create($data);
    }

    public function findById(string $id): ?Account
    {
        return Account::find($id);
    }

    public function existsByEmail(string $email): bool
    {
        return Account::where('email', $email)->exists();
    }

    public function existsByAccountNumber(string $accountNumber): bool
    {
        return Account::where('account_number', $accountNumber)->exists();
    }

    public function findByIdWithRelations(string $id, array $relations = []): ?Account
    {
        return Account::with($relations)->find($id);
    }

    public function paginate(AccountListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Account::orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(AccountSearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Account::query();

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('account_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('account_number', 'like', "%{$criteria->keyword}%")
                  ->orWhere('email', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->status !== null) {
            $query->where('status', $criteria->status);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Account $account, UpdateAccountDTO $dto): Account
    {
        $account->update($dto->toArray());
        return $account;
    }

    public function updateStatus(Account $account, string $status): Account
    {
        $account->update(['status' => $status]);
        return $account;
    }
}
