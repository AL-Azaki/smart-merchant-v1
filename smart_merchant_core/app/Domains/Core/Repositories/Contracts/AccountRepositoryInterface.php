<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Models\Core\Account;

interface AccountRepositoryInterface
{
    public function create(array $data): Account;

    public function findById(string $id): ?Account;

    public function existsByEmail(string $email): bool;

    public function existsByAccountNumber(string $accountNumber): bool;

    public function findByIdWithRelations(string $id, array $relations = []): ?Account;

    public function paginate(\App\Domains\Core\DTOs\AccountListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\AccountSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Account $account, \App\Domains\Core\DTOs\UpdateAccountDTO $dto): Account;

    public function updateStatus(Account $account, string $status): Account;
}
