<?php

namespace App\Domains\Core\DTOs;

class ViewAccountDTO
{
    public function __construct(
        public readonly string $accountId,
        public readonly array $includes = []
    ) {}

    public static function fromRequest(array $data, string $accountId): self
    {
        $includes = isset($data['include']) ? array_filter(array_map('trim', explode(',', $data['include']))) : [];
        return new self($accountId, $includes);
    }
}
