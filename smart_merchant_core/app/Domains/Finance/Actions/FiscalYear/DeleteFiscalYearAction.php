<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(string $fiscalYearId, string $businessId): bool
    {
        $fiscalYear = $this->repository->findById($fiscalYearId);

        if (!$fiscalYear || $fiscalYear->business_id !== $businessId) {
            throw new ModelNotFoundException("Fiscal year not found.");
        }

        if ($fiscalYear->status === 'Closed') {
            throw ValidationException::withMessages(['id' => 'Cannot delete a closed fiscal year.']);
        }

        if ($this->repository->hasPeriods($fiscalYear->id)) {
            throw ValidationException::withMessages(['id' => 'Cannot delete a fiscal year that has fiscal periods.']);
        }

        if ($this->repository->hasPostedJournalEntries($fiscalYear->id)) {
            throw ValidationException::withMessages(['id' => 'Cannot delete a fiscal year that has posted journal entries.']);
        }

        return $this->repository->delete($fiscalYear);
    }
}
