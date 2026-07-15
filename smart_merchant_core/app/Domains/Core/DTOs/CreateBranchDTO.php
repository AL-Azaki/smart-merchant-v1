<?php

namespace App\Domains\Core\DTOs;

class CreateBranchDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchName,
        public readonly string $branchCode,
        public readonly ?string $phone,
        public readonly ?string $email,
        public readonly ?string $address,
        public readonly bool $isActive = true
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            branchName: $data['branch_name'],
            branchCode: $data['branch_code'],
            phone: $data['phone'] ?? null,
            email: $data['email'] ?? null,
            address: $data['address'] ?? null,
            isActive: $data['is_active'] ?? true,
        );
    }
}
