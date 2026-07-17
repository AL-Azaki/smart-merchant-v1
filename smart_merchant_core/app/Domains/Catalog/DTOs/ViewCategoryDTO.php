<?php

namespace App\Domains\Catalog\DTOs;

class ViewCategoryDTO
{
    public function __construct(public readonly string $categoryId) {}

    public static function fromRequest(array $data, string $categoryId): self
    {
        return new self($categoryId);
    }
}




