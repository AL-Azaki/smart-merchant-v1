<?php

namespace App\Domains\Finance\Services\PostingEngine;

use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Finance\DTOs\PostingEngine\ReverseRequestDTO;
use Illuminate\Support\Facades\DB;

class PostingEngine implements PostingEngineInterface
{
    private ValidationLayer $validationLayer;
    private JournalBuilder $journalBuilder;
    private ReverseBuilder $reverseBuilder;

    public function __construct(
        ValidationLayer $validationLayer,
        JournalBuilder $journalBuilder,
        ReverseBuilder $reverseBuilder
    ) {
        $this->validationLayer = $validationLayer;
        $this->journalBuilder = $journalBuilder;
        $this->reverseBuilder = $reverseBuilder;
    }

    public function post(PostingRequestDTO $request): PostingResultDTO
    {
        return DB::transaction(function () use ($request) {
            // 1. Validate the Request
            $this->validationLayer->validate($request);

            // 2. Build and persist Journal Entry & Lines
            $journal = $this->journalBuilder->build($request);

            // 3. Return the Result DTO
            return new PostingResultDTO(
                $journal->id,
                $journal->journal_number,
                $journal->status,
                $journal->posting_date->toDateString()
            );
        });
    }

    public function reverse(ReverseRequestDTO $request): PostingResultDTO
    {
        return DB::transaction(function () use ($request) {
            // 1. Build and persist Reverse Journal (Includes its own validations)
            $reverseJournal = $this->reverseBuilder->build($request);

            // 2. Return the Result DTO
            return new PostingResultDTO(
                $reverseJournal->id,
                $reverseJournal->journal_number,
                $reverseJournal->status,
                $reverseJournal->posting_date->toDateString()
            );
        });
    }
}
