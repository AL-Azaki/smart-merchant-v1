<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\JournalEntryLine;
use Illuminate\Support\Collection;

interface JournalEntryLineRepositoryInterface
{
    public function createMany(array $linesData): Collection;
}
