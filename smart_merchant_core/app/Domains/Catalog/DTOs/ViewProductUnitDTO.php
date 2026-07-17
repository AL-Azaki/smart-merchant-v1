<?php

namespace App\Domains\Catalog\DTOs;

class ViewproductUnitUnitDTO
{
    public function __construct(public readonly string $productUnitUnitId) {}

    public static function fromRequest(array $data, string $productUnitUnitId): self
    {
        return new self($productUnitUnitId);
    }
}






