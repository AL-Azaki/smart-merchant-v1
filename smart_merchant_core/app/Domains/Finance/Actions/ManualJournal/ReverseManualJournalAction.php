<?php

namespace App\Domains\Finance\Actions\ManualJournal;

use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\ManualJournal\ReverseManualJournalDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Finance\DTOs\PostingEngine\ReverseRequestDTO;
use App\Domains\Finance\Exceptions\PostingEngineException;

class ReverseManualJournalAction
{
    private PostingEngineInterface $postingEngine;

    public function __construct(PostingEngineInterface $postingEngine)
    {
        $this->postingEngine = $postingEngine;
    }

    /**
     * @throws PostingEngineException
     */
    public function execute(ReverseManualJournalDTO $dto): PostingResultDTO
    {
        $requestDTO = new ReverseRequestDTO(
            $dto->originalJournalId,
            $dto->postingDate,
            $dto->reversedBy,
            $dto->description
        );

        // Exceptional handling is delegated to the caller or handled natively by PostingEngineException
        return $this->postingEngine->reverse($requestDTO);
    }
}
