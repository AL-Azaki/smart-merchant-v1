<?php

namespace App\Domains\Finance\DTOs\Integration;

class NotificationRequestDTO
{
    public array $recipientIds;
    public array $channels;
    public string $title;
    public string $body;
    public array $metadata;

    public function __construct(
        array $recipientIds,
        array $channels,
        string $title,
        string $body,
        array $metadata = []
    ) {
        $this->recipientIds = $recipientIds;
        $this->channels = $channels;
        $this->title = $title;
        $this->body = $body;
        $this->metadata = $metadata;
    }
}
