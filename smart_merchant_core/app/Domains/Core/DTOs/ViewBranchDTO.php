<?php

namespace App\Domains\Core\DTOs;

class ViewBranchDTO
{
    public function __construct(
        public readonly string $branchId,
        public readonly array $includes = []
    ) {}

    public static function fromRequest(array $data, string $branchId): self
    {
        $includes = isset($data['include']) ? array_filter(array_map('trim', explode(',', $data['include']))) : [];
        
        return new self(
            branchId: $branchId,
            includes: $includes
        );
    }
}
