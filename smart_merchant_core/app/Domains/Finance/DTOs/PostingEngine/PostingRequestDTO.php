<?php

namespace App\Domains\Finance\DTOs\PostingEngine;

class PostingRequestDTO
{
    public string $businessId;
    public string $fiscalPeriodId;
    public string $documentDate;
    public string $postingDate;
    public string $journalType;
    public string $documentType;
    public ?string $documentId;
    public ?string $documentNumber;
    public string $currencyId;
    public float $exchangeRate;
    public ?string $description;
    public string $createdBy;

    /** @var PostingLineDTO[] */
    public array $lines = [];

    public function __construct(
        string $businessId,
        string $fiscalPeriodId,
        string $documentDate,
        string $postingDate,
        string $journalType,
        string $documentType,
        ?string $documentId,
        ?string $documentNumber,
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
        $this->journalType = $journalType;
        $this->documentType = $documentType;
        $this->documentId = $documentId;
        $this->documentNumber = $documentNumber;
        $this->currencyId = $currencyId;
        $this->exchangeRate = $exchangeRate;
        $this->description = $description;
        $this->createdBy = $createdBy;
        $this->lines = $lines;
    }
}
