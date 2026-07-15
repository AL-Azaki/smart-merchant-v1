<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\AccountType;
use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;

class AccountTypeEloquentRepository implements AccountTypeRepositoryInterface
{
    /**
     * Get all active account types.
     *
     * @return Collection
     */
    public function getAllActive(): Collection
    {
        return AccountType::where('is_active', true)->get();
    }

    /**
     * Find an account type by its ID.
     *
     * @param int $id
     * @return AccountType|null
     */
    public function findById(int $id): ?AccountType
    {
        return AccountType::find($id);
    }
}
