<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\DTOs\UpdateFiscalPeriodDTO;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateFiscalPeriodAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(UpdateFiscalPeriodDTO $dto): FiscalPeriod
    {
        $fiscalPeriod = $this->repository->findById($dto->fiscalPeriodId);

        if (!$fiscalPeriod || $fiscalPeriod->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Fiscal period not found.");
        }

        if ($fiscalPeriod->status === 'Closed') {
            throw ValidationException::withMessages(['status' => 'Cannot update a closed fiscal period.']);
        }

        // Check if dates are being modified
        if ($fiscalPeriod->start_date->format('Y-m-d') !== $dto->startDate || $fiscalPeriod->end_date->format('Y-m-d') !== $dto->endDate) {
            
            // Check if modification would push any journal entries out of bounds
            if ($this->repository->hasJournalEntriesOutsideDates($fiscalPeriod->id, $dto->startDate, $dto->endDate)) {
                throw ValidationException::withMessages(['start_date' => 'Cannot modify dates. Existing journal entries would fall outside the new boundaries.']);
            }

            // Boundary Check: Ensure period dates are within the fiscal year's dates
            $fiscalYear = $fiscalPeriod->fiscalYear;
            if ($dto->startDate < $fiscalYear->start_date->format('Y-m-d') || $dto->endDate > $fiscalYear->end_date->format('Y-m-d')) {
                throw ValidationException::withMessages(['start_date' => 'Fiscal period dates must be within the fiscal year boundaries.']);
            }

            // Overlap Check: Ensure period does not overlap with existing periods in the same year
            $overlapping = $this->repository->findOverlapping($fiscalPeriod->fiscal_year_id, $dto->startDate, $dto->endDate, $fiscalPeriod->id);
            if ($overlapping) {
                throw ValidationException::withMessages(['start_date' => 'The dates overlap with an existing fiscal period.']);
            }
        }

        $data = [
            'period_name' => $dto->periodName,
            'start_date' => $dto->startDate,
            'end_date' => $dto->endDate,
        ];

        return $this->repository->update($fiscalPeriod, $data);
    }
}
