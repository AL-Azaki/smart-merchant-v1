<?php

namespace App\Domains\Core\DTOs;

class ViewCurrencyDTO
{
    public function __construct(public readonly string $currencyId) {}

    public static function fromRequest(array $data, string $currencyId): self
    {
        return new self($currencyId);
    }
}
