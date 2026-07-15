<?php

namespace App\Domains\Finance\DTOs\PostingEngine;

class PostingLineDTO
{
    public string $chartOfAccountId;
    public string $type; // Debit or Credit
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
