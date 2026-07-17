<?php

namespace App\Domains\Catalog\DTOs;

class ViewUnitDTO
{
    public function __construct(public readonly string $UnitId) {}

    public static function fromRequest(array $data, string $UnitId): self
    {
        return new self($UnitId);
    }
}


