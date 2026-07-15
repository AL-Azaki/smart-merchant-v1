<?php

namespace App\Domains\Core\DTOs;

class CreateAccountDTO
{
    public function __construct(
        public readonly string $accountName,
        public readonly string $email,
        public readonly ?string $phone = null,
        public readonly ?string $accountNumber = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            accountName: $data['account_name'],
            email: $data['email'],
            phone: $data['phone'] ?? null,
            accountNumber: $data['account_number'] ?? null
        );
    }
}
