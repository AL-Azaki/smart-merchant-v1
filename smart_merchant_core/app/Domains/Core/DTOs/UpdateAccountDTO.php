<?php

namespace App\Domains\Core\DTOs;

class UpdateAccountDTO
{
    public function __construct(
        public readonly ?string $accountName = null,
        public readonly ?string $email = null,
        public readonly ?string $phone = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            accountName: $data['account_name'] ?? null,
            email: $data['email'] ?? null,
            phone: $data['phone'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'account_name' => $this->accountName,
            'email'        => $this->email,
            'phone'        => $this->phone,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}
