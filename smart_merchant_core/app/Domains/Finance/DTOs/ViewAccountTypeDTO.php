<?php

namespace App\Domains\Finance\DTOs;

class ViewAccountTypeDTO
{
    public function __construct(public readonly int $id) {}

    public static function fromRequest(int $id): self
    {
        return new self($id);
    }
}
