<?php

namespace App\Domains\Core\DTOs;

class UpdateCurrencyDTO
{
    public function __construct(
        public readonly ?string $name = null,
        public readonly ?string $symbol = null,
        // @todo: Temporary field, will be replaced by ExchangeRate Entity in Finance Domain
        public readonly ?float $exchangeRate = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            name: $data['name'] ?? null,
            symbol: $data['symbol'] ?? null,
            exchangeRate: isset($data['exchange_rate']) ? (float) $data['exchange_rate'] : null
        );
    }

    public function toArray(): array
    {
        $data = [
            'name'          => $this->name,
            'symbol'        => $this->symbol,
            'exchange_rate' => $this->exchangeRate,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}
