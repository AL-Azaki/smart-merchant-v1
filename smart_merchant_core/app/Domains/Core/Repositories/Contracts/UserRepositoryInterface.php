<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\User;

interface UserRepositoryInterface
{
    public function create(array $data): User;

    public function findById(string $id): ?User;

    public function existsByEmail(string $email): bool;

    public function existsByUsernameInBusiness(string $businessId, string $username): bool;

    public function findByIdWithRelations(string $id, array $relations = []): ?User;

    public function paginate(\App\Domains\Core\DTOs\UserListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\UserSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(User $user, \App\Domains\Core\DTOs\UpdateUserDTO $dto): User;

    public function updateStatus(User $user, string $status): User;

    public function syncRoles(User $user, array $roleIds): void;

    public function syncBranches(User $user, array $branchIds): void;
}
