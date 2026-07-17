<?php

namespace App\Domains\Catalog\DTOs;

class ViewProductDTO
{
    public function __construct(public readonly string $ProductId) {}

    public static function fromRequest(array $data, string $ProductId): self
    {
        return new self($ProductId);
    }
}





