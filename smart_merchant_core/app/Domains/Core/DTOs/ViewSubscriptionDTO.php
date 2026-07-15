<?php

namespace App\Domains\Core\DTOs;

class ViewSubscriptionDTO
{
    public function __construct(
        public readonly string $subscriptionId,
        public readonly array $includes = []
    ) {}

    public static function fromRequest(array $data, string $subscriptionId): self
    {
        $includes = isset($data['include']) ? array_filter(array_map('trim', explode(',', $data['include']))) : [];
        return new self($subscriptionId, $includes);
    }
}
