<?php

namespace App\Domains\Core\DTOs;

class CurrencyDTO
{
    public function __construct(
        public readonly string $currencyCode,
        public readonly string $currencyName,
        public readonly ?string $symbol = null,
        public readonly float $exchangeRate = 1.0,
        public readonly bool $isDefault = false,
        public readonly bool $isActive = true
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            currencyCode: $data['currency_code'],
            currencyName: $data['currency_name'],
            symbol: $data['symbol'] ?? null,
            exchangeRate: $data['exchange_rate'] ?? 1.0,
            isDefault: $data['is_default'] ?? false,
            isActive: $data['is_active'] ?? true
        );
    }

    public function toArray(): array
    {
        return [
            'currency_code' => $this->currencyCode,
            'currency_name' => $this->currencyName,
            'symbol' => $this->symbol,
            'exchange_rate' => $this->exchangeRate,
            'is_default' => $this->isDefault,
            'is_active' => $this->isActive,
        ];
    }
}
