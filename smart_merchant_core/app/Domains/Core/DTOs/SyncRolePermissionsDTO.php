<?php

namespace App\Domains\Core\DTOs;

class SyncRolePermissionsDTO
{
    public function __construct(
        public readonly string $roleId,
        public readonly string $businessId,
        public readonly array $permissionIds
    ) {}

    public static function fromRequest(array $data, string $roleId, string $businessId): self
    {
        return new self(
            roleId: $roleId,
            businessId: $businessId,
            permissionIds: $data['permission_ids'] ?? []
        );
    }
}
