<?php

namespace App\Domains\Catalog\DTOs;

class ViewBranchbranchProductPricePriceDTO
{
    public function __construct(public readonly string $BranchbranchProductPricePriceId) {}

    public static function fromRequest(array $data, string $BranchbranchProductPricePriceId): self
    {
        return new self($BranchbranchProductPricePriceId);
    }
}






