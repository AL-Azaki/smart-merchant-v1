<?php

namespace App\Domains\Finance\DTOs\ManualJournal;

class CreateManualJournalLineDTO
{
    public string $chartOfAccountId;
    public string $type;
    public float $foreignAmount;
    public float $baseAmount;
    public ?string $description;

    public function __construct(
        string $chartOfAccountId,
        string $type,
        float $foreignAmount,
        float $baseAmount,
        ?string $description = null
    ) {
        $this->chartOfAccountId = $chartOfAccountId;
        $this->type = $type;
        $this->foreignAmount = $foreignAmount;
        $this->baseAmount = $baseAmount;
        $this->description = $description;
    }
}
