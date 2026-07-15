<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\DTOs\UpdateFiscalYearDTO;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(UpdateFiscalYearDTO $dto): FiscalYear
    {
        $fiscalYear = $this->repository->findById($dto->fiscalYearId);

        if (!$fiscalYear || $fiscalYear->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Fiscal year not found.");
        }

        if ($fiscalYear->status === 'Closed') {
            throw ValidationException::withMessages(['status' => 'Cannot update a closed fiscal year.']);
        }

        // Check if dates are being modified
        if ($fiscalYear->start_date->format('Y-m-d') !== $dto->startDate || $fiscalYear->end_date->format('Y-m-d') !== $dto->endDate) {
            
            // Check for posted journal entries
            if ($this->repository->hasPostedJournalEntries($fiscalYear->id)) {
                throw ValidationException::withMessages(['start_date' => 'Cannot modify dates of a fiscal year that has posted journal entries.']);
            }

            // Check for overlapping with other years
            $overlapping = $this->repository->findOverlapping($dto->businessId, $dto->startDate, $dto->endDate, $fiscalYear->id);
            if ($overlapping) {
                throw ValidationException::withMessages(['start_date' => 'The dates overlap with an existing fiscal year.']);
            }

            // Rule: "لا يسمح بتعديل تاريخ بداية أو نهاية FiscalYear إذا أدى ذلك إلى خروج أي FiscalPeriod موجودة خارج الحدود الزمنية للسنة."
            if ($this->repository->hasPeriods($fiscalYear->id)) {
                $earliestPeriod = $fiscalYear->periods()->min('start_date');
                $latestPeriod = $fiscalYear->periods()->max('end_date');

                if ($dto->startDate > $earliestPeriod || $dto->endDate < $latestPeriod) {
                    throw ValidationException::withMessages(['start_date' => 'Cannot modify dates to exclude existing fiscal periods.']);
                }
            }
        }

        $data = [
            'fiscal_year_name' => $dto->fiscalYearName,
            'description' => $dto->description,
            'start_date' => $dto->startDate,
            'end_date' => $dto->endDate,
        ];

        return $this->repository->update($fiscalYear, $data);
    }
}
