<?php

namespace App\Domains\Core\DTOs;

class CreateCurrencyDTO
{
    public function __construct(
        public readonly string $name,
        public readonly string $code,
        public readonly string $symbol,
        // @todo: Temporary field, will be replaced by ExchangeRate Entity in Finance Domain
        public readonly float $exchangeRate = 1.0
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'],
            code: strtoupper($data['code']),
            symbol: $data['symbol'],
            exchangeRate: (float) ($data['exchange_rate'] ?? 1.0)
        );
    }
}
