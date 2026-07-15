<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class CloseFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(string $fiscalYearId, string $businessId): FiscalYear
    {
        $fiscalYear = $this->repository->findById($fiscalYearId);

        if (!$fiscalYear || $fiscalYear->business_id !== $businessId) {
            throw new ModelNotFoundException("Fiscal year not found.");
        }

        if ($fiscalYear->status === 'Closed') {
            throw ValidationException::withMessages(['status' => 'Fiscal year is already closed.']);
        }

        if ($this->repository->getOpenPeriodsCount($fiscalYear->id) > 0) {
            throw ValidationException::withMessages(['status' => 'Cannot close fiscal year with open fiscal periods.']);
        }

        return $this->repository->update($fiscalYear, ['status' => 'Closed']);
    }
}
