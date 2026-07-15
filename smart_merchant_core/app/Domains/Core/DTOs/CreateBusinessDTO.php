<?php

namespace App\Domains\Core\DTOs;

class CreateBusinessDTO
{
    public function __construct(
        // Business Data
        public readonly string $accountId,
        public readonly string $businessName,
        public readonly ?string $businessType,
        public readonly string $primaryPhone,
        public readonly string $primaryEmail,
        public readonly ?string $logoPath,

        // Owner Data
        public readonly string $ownerName,
        public readonly string $ownerEmail,
        public readonly string $ownerUsername,
        public readonly string $ownerPassword,

        // Plan & Subscription
        public readonly string $planId,
        public readonly string $currencyId,

        // Settings
        public readonly ?string $country,
        public readonly ?string $timezone,
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            accountId: $data['account_id'],
            businessName: $data['business_name'],
            businessType: $data['business_type'] ?? null,
            primaryPhone: $data['primary_phone'],
            primaryEmail: $data['primary_email'],
            logoPath: $data['logo_path'] ?? null,
            ownerName: $data['owner_name'],
            ownerEmail: $data['owner_email'],
            ownerUsername: $data['owner_username'],
            ownerPassword: $data['owner_password'],
            planId: $data['plan_id'],
            currencyId: $data['currency_id'],
            country: $data['country'] ?? null,
            timezone: $data['timezone'] ?? null,
        );
    }
}
