<?php

namespace App\Domains\Catalog\DTOs;

class ViewproductImageImageDTO
{
    public function __construct(public readonly string $productImageImageId) {}

    public static function fromRequest(array $data, string $productImageImageId): self
    {
        return new self($productImageImageId);
    }
}






