<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Business;

interface BusinessRepositoryInterface
{
    public function create(array $data): Business;

    public function findById(string $id): ?Business;

    public function findByIdOrFail(string $id): Business;

    public function existsByNameInAccount(string $accountId, string $businessName): bool;
}
