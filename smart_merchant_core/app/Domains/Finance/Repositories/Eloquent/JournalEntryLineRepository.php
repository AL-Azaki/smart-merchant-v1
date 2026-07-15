<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\JournalEntryLine;
use App\Domains\Finance\Repositories\Contracts\JournalEntryLineRepositoryInterface;
use Illuminate\Support\Collection;

class JournalEntryLineRepository implements JournalEntryLineRepositoryInterface
{
    public function createMany(array $linesData): Collection
    {
        $createdLines = collect();
        foreach ($linesData as $data) {
            $createdLines->push(JournalEntryLine::create($data));
        }
        return $createdLines;
    }
}
