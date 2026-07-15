<?php

namespace App\Domains\Core\DTOs;

class ViewPermissionDTO
{
    public function __construct(public readonly string $permissionId) {}

    public static function fromRequest(array $data, string $permissionId): self
    {
        return new self($permissionId);
    }
}
