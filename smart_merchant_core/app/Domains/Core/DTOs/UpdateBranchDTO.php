<?php

namespace App\Domains\Core\DTOs;

class UpdateBranchDTO
{
    public function __construct(
        public readonly ?string $branchName = null,
        public readonly ?string $branchCode = null,
        public readonly ?string $phone = null,
        public readonly ?string $email = null,
        public readonly ?string $address = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            branchName: $data['branch_name'] ?? null,
            branchCode: $data['branch_code'] ?? null,
            phone: $data['phone'] ?? null,
            email: $data['email'] ?? null,
            address: $data['address'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'branch_name' => $this->branchName,
            'branch_code' => $this->branchCode,
            'phone'       => $this->phone,
            'email'       => $this->email,
            'address'     => $this->address,
        ];

        // Return only non-null fields to support PATCH semantics
        return array_filter($data, fn($value) => $value !== null);
    }
}
