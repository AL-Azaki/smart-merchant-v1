<?php

namespace App\Domains\Finance\Actions\FiscalYear;

use App\Domains\Finance\DTOs\ViewFiscalYearDTO;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(ViewFiscalYearDTO $dto): FiscalYear
    {
        $fiscalYear = $this->repository->findById($dto->fiscalYearId);

        if (!$fiscalYear || $fiscalYear->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Fiscal year not found.");
        }

        return $fiscalYear;
    }
}
