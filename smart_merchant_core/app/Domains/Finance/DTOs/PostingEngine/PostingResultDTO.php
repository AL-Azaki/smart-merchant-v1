<?php

namespace App\Domains\Finance\DTOs\PostingEngine;

class PostingResultDTO
{
    public string $journalEntryId;
    public string $journalNumber;
    public string $status;
    public string $postingDate;

    public function __construct(
        string $journalEntryId,
        string $journalNumber,
        string $status,
        string $postingDate
    ) {
        $this->journalEntryId = $journalEntryId;
        $this->journalNumber = $journalNumber;
        $this->status = $status;
        $this->postingDate = $postingDate;
    }
}
