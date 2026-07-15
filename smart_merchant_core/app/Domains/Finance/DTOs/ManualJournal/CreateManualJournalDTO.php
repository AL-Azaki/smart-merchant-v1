<?php

namespace App\Domains\Finance\DTOs\ManualJournal;

class CreateManualJournalDTO
{
    public string $businessId;
    public string $fiscalPeriodId;
    public string $documentDate;
    public string $postingDate;
    public string $currencyId;
    public float $exchangeRate;
    public ?string $description;
    public string $createdBy;
    
    /** @var CreateManualJournalLineDTO[] */
    public array $lines = [];

    public function __construct(
        string $businessId,
        string $fiscalPeriodId,
        string $documentDate,
        string $postingDate,
        string $currencyId,
        float $exchangeRate,
        ?string $description,
        string $createdBy,
        array $lines
    ) {
        $this->businessId = $businessId;
        $this->fiscalPeriodId = $fiscalPeriodId;
        $this->documentDate = $documentDate;
        $this->postingDate = $postingDate;
        $this->currencyId = $currencyId;
        $this->exchangeRate = $exchangeRate;
        $this->description = $description;
        $this->createdBy = $createdBy;
        $this->lines = $lines;
    }
}
