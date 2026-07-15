<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\DTOs\CreateFiscalPeriodDTO;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateFiscalPeriodAction
{
    public function __construct(
        private readonly FiscalPeriodRepositoryInterface $repository,
        private readonly FiscalYearRepositoryInterface $fiscalYearRepository
    ) {}

    public function handle(CreateFiscalPeriodDTO $dto): FiscalPeriod
    {
        $fiscalYear = $this->fiscalYearRepository->findById($dto->fiscalYearId);

        if (!$fiscalYear || $fiscalYear->business_id !== $dto->businessId) {
            throw ValidationException::withMessages(['fiscal_year_id' => 'Invalid fiscal year.']);
        }

        if ($fiscalYear->status === 'Closed') {
            throw ValidationException::withMessages(['fiscal_year_id' => 'Cannot create a fiscal period within a closed fiscal year.']);
        }

        // Check if period number is unique for this year
        $existingNumber = $this->repository->findByNumber($dto->fiscalYearId, $dto->periodNumber);
        if ($existingNumber) {
            throw ValidationException::withMessages(['period_number' => 'Period number must be unique within the fiscal year.']);
        }

        // Boundary Check: Ensure period dates are within the fiscal year's dates
        if ($dto->startDate < $fiscalYear->start_date->format('Y-m-d') || $dto->endDate > $fiscalYear->end_date->format('Y-m-d')) {
            throw ValidationException::withMessages(['start_date' => 'Fiscal period dates must be within the fiscal year boundaries.']);
        }

        // Overlap Check: Ensure period does not overlap with existing periods in the same year
        $overlapping = $this->repository->findOverlapping($dto->fiscalYearId, $dto->startDate, $dto->endDate);
        if ($overlapping) {
            throw ValidationException::withMessages(['start_date' => 'The dates overlap with an existing fiscal period.']);
        }

        $data = [
            'business_id' => $dto->businessId,
            'fiscal_year_id' => $dto->fiscalYearId,
            'period_number' => $dto->periodNumber,
            'period_name' => $dto->periodName,
            'start_date' => $dto->startDate,
            'end_date' => $dto->endDate,
            'status' => 'Open',
        ];

        return $this->repository->create($data);
    }
}
