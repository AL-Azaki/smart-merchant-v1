<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteFiscalPeriodAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(string $fiscalPeriodId, string $businessId): bool
    {
        $fiscalPeriod = $this->repository->findById($fiscalPeriodId);

        if (!$fiscalPeriod || $fiscalPeriod->business_id !== $businessId) {
            throw new ModelNotFoundException("Fiscal period not found.");
        }

        if ($fiscalPeriod->status === 'Closed') {
            throw ValidationException::withMessages(['id' => 'Cannot delete a closed fiscal period.']);
        }

        if ($this->repository->hasPostedJournalEntries($fiscalPeriod->id)) {
            throw ValidationException::withMessages(['id' => 'Cannot delete a fiscal period that has posted journal entries.']);
        }

        return $this->repository->delete($fiscalPeriod);
    }
}
