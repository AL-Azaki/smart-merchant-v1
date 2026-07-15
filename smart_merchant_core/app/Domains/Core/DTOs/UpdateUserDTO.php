<?php

namespace App\Domains\Core\DTOs;

class UpdateUserDTO
{
    public function __construct(
        public readonly ?string $fullName = null,
        public readonly ?string $username = null,
        public readonly ?string $languageId = null,
        public readonly ?string $timezoneId = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            fullName: $data['full_name'] ?? null,
            username: $data['username'] ?? null,
            languageId: $data['language_id'] ?? null,
            timezoneId: $data['timezone_id'] ?? null
        );
    }

    public function toArray(): array
    {
        $data = [
            'full_name'   => $this->fullName,
            'username'    => $this->username,
            'language_id' => $this->languageId,
            'timezone_id' => $this->timezoneId,
        ];
        return array_filter($data, fn($value) => $value !== null);
    }
}
