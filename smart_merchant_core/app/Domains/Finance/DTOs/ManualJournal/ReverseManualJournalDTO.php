<?php

namespace App\Domains\Finance\DTOs\ManualJournal;

class ReverseManualJournalDTO
{
    public string $originalJournalId;
    public string $postingDate;
    public string $reversedBy;
    public ?string $description;

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
