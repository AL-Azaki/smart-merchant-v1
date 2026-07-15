<?php

namespace App\Domains\Finance\DTOs\PostingEngine;

class ReverseRequestDTO
{
    public string $originalJournalId;
    public string $postingDate;
    public ?string $description;
    public string $reversedBy;

    public function __construct(
        string $originalJournalId,
        string $postingDate,
        string $reversedBy,
        ?string $description = null
    ) {
        $this->originalJournalId = $originalJournalId;
        $this->postingDate = $postingDate;
        $this->reversedBy = $reversedBy;
        $this->description = $description;
    }
}
