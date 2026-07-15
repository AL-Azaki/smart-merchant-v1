<?php

namespace App\Domains\Core\DTOs;

class ViewPlanDTO
{
    public function __construct(public readonly string $planId) {}

    public static function fromRequest(array $data, string $planId): self
    {
        return new self($planId);
    }
}
