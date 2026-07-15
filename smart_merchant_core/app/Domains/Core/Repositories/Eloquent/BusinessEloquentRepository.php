<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Repositories\Contracts\BusinessRepositoryInterface;

class BusinessEloquentRepository implements BusinessRepositoryInterface
{
    public function create(array $data): Business
    {
        return Business::create($data);
    }

    public function findById(string $id): ?Business
    {
        return Business::find($id);
    }

    public function findByIdOrFail(string $id): Business
    {
        return Business::findOrFail($id);
    }

    public function existsByNameInAccount(string $accountId, string $businessName): bool
    {
        return Business::where('account_id', $accountId)
            ->where('business_name', $businessName)
            ->exists();
    }
}
