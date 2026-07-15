<?php

namespace App\Domains\Finance\Repositories\Contracts;

use Illuminate\Database\Eloquent\Collection;
use App\Domains\Finance\Models\AccountType;

interface AccountTypeRepositoryInterface
{
    /**
     * Get all active account types.
     *
     * @return Collection
     */
    public function getAllActive(): Collection;

    /**
     * Find an account type by its ID.
     *
     * @param int $id
     * @return AccountType|null
     */
    public function findById(int $id): ?AccountType;
}
