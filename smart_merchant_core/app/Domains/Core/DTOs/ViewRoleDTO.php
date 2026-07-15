<?php

namespace App\Domains\Core\DTOs;

class ViewRoleDTO
{
    public function __construct(
        public readonly string $roleId,
        public readonly array $includes = []
    ) {}

    public static function fromRequest(array $data, string $roleId): self
    {
        $includes = isset($data['include']) ? array_filter(array_map('trim', explode(',', $data['include']))) : [];
        return new self($roleId, $includes);
    }
}
