<?php

namespace App\Domains\Finance\Actions\ManualJournal;

use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\ManualJournal\CreateManualJournalDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingLineDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Finance\Exceptions\PostingEngineException;

class CreateManualJournalAction
{
    private PostingEngineInterface $postingEngine;

    public function __construct(PostingEngineInterface $postingEngine)
    {
        $this->postingEngine = $postingEngine;
    }

    /**
     * @throws PostingEngineException
     */
    public function execute(CreateManualJournalDTO $dto): PostingResultDTO
    {
        $lines = [];
        foreach ($dto->lines as $lineDto) {
            $lines[] = new PostingLineDTO(
                $lineDto->chartOfAccountId,
                $lineDto->type,
                $lineDto->foreignAmount,
                $lineDto->baseAmount,
                $lineDto->description
            );
        }

        $requestDTO = new PostingRequestDTO(
            $dto->businessId,
            $dto->fiscalPeriodId,
            $dto->documentDate,
            $dto->postingDate,
            'Manual', // journalType
            'Manual', // documentType
            null,     // documentId
            null,     // documentNumber
            $dto->currencyId,
            $dto->exchangeRate,
            $dto->description,
            $dto->createdBy,
            $lines
        );

        // Exceptional handling is delegated to the caller or handled natively by PostingEngineException
        return $this->postingEngine->post($requestDTO);
    }
}
