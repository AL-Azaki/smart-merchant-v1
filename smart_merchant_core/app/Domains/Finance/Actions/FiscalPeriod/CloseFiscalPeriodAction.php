<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class CloseFiscalPeriodAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(string $fiscalPeriodId, string $businessId): FiscalPeriod
    {
        $fiscalPeriod = $this->repository->findById($fiscalPeriodId);

        if (!$fiscalPeriod || $fiscalPeriod->business_id !== $businessId) {
            throw new ModelNotFoundException("Fiscal period not found.");
        }

        if ($fiscalPeriod->status === 'Closed') {
            throw ValidationException::withMessages(['status' => 'Fiscal period is already closed.']);
        }

        if ($this->repository->hasDraftJournalEntries($fiscalPeriod->id)) {
            throw ValidationException::withMessages(['status' => 'Cannot close a fiscal period that has draft journal entries. All entries must be posted or deleted.']);
        }

        return $this->repository->update($fiscalPeriod, ['status' => 'Closed']);
    }
}
