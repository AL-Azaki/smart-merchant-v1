<?php

namespace App\Domains\Core\DTOs;

class CreateUserDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $fullName,
        public readonly string $username,
        public readonly string $email,
        public readonly string $password,
        public readonly ?string $languageId,
        public readonly ?string $timezoneId,
        public readonly array $roleIds = [],
        public readonly array $branchIds = []
    ) {}

    public static function fromRequest(array $data, string $businessId): self
    {
        return new self(
            businessId: $businessId,
            fullName: $data['full_name'],
            username: $data['username'],
            email: $data['email'],
            password: $data['password'],
            languageId: $data['language_id'] ?? null,
            timezoneId: $data['timezone_id'] ?? null,
            roleIds: $data['role_ids'] ?? [],
            branchIds: $data['branch_ids'] ?? []
        );
    }
}
