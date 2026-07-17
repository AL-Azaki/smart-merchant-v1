<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\User;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;

class UserEloquentRepository implements UserRepositoryInterface
{
    public function create(array $data): User
    {
        return User::create($data);
    }

    public function findById(string $id): ?User
    {
        return User::find($id);
    }

    public function existsByEmail(string $email): bool
    {
        return User::where('email', $email)->exists();
    }

    public function existsByUsernameInBusiness(string $businessId, string $username): bool
    {
        return User::where('business_id', $businessId)
            ->where('username', $username)
            ->exists();
    }

    public function findByIdWithRelations(string $id, array $relations = []): ?User
    {
        return User::with($relations)->find($id);
    }

    public function paginate(\App\Domains\Core\DTOs\UserListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        return User::where('business_id', $criteria->businessId)
            ->with($criteria->includes)
            ->orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(\App\Domains\Core\DTOs\UserSearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $query = User::where('business_id', $criteria->businessId)
            ->with($criteria->includes);

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('full_name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('username', 'like', "%{$criteria->keyword}%")
                  ->orWhere('email', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->status !== null) {
            $query->where('status', $criteria->status);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(User $user, \App\Domains\Core\DTOs\UpdateUserDTO $dto): User
    {
        $user->update($dto->toArray());
        return $user;
    }

    public function updateStatus(User $user, string $status): User
    {
        $user->update(['status' => $status]);
        return $user;
    }

    public function syncRoles(User $user, array $roleIds): void
    {
        $user->roles()->sync($roleIds);
    }

    public function syncBranches(User $user, array $branchIds): void
    {
        $user->branches()->sync($branchIds);
    }

    public function assignToBranch(string $userId, string $branchId): void
    {
        $user = User::find($userId);
        if ($user) {
            $user->branches()->syncWithoutDetaching([$branchId]);
        }
    }

    public function setDefaultBranch(string $userId, string $branchId): void
    {
        $user = User::find($userId);
        if ($user) {
            $user->update(['default_branch_id' => $branchId]);
        }
    }
}
