<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\DTOs\CreateFiscalYearDTO;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(CreateFiscalYearDTO $dto): FiscalYear
    {
        // 1. Check if code is unique for this business
        $existingCode = $this->repository->findByCode($dto->businessId, $dto->fiscalYearCode);
        if ($existingCode) {
            throw ValidationException::withMessages(['fiscal_year_code' => 'Fiscal year code must be unique.']);
        }

        // 2. Check for overlapping dates
        $overlapping = $this->repository->findOverlapping($dto->businessId, $dto->startDate, $dto->endDate);
        if ($overlapping) {
            throw ValidationException::withMessages(['start_date' => 'The dates overlap with an existing fiscal year.']);
        }

        // The business rule "no number of open years is enforced, only non-overlapping" is satisfied.

        $data = [
            'business_id' => $dto->businessId,
            'fiscal_year_code' => $dto->fiscalYearCode,
            'fiscal_year_name' => $dto->fiscalYearName,
            'description' => $dto->description,
            'start_date' => $dto->startDate,
            'end_date' => $dto->endDate,
            'status' => 'Open',
        ];

        return $this->repository->create($data);
    }
}
