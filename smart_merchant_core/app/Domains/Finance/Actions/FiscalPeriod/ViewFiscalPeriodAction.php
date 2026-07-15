<?php

namespace App\Domains\Finance\Actions\FiscalPeriod;

use App\Domains\Finance\DTOs\ViewFiscalPeriodDTO;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewFiscalPeriodAction
{
    public function __construct(private readonly FiscalPeriodRepositoryInterface $repository) {}

    public function handle(ViewFiscalPeriodDTO $dto): FiscalPeriod
    {
        $fiscalPeriod = $this->repository->findById($dto->fiscalPeriodId);

        if (!$fiscalPeriod || $fiscalPeriod->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Fiscal period not found.");
        }

        return $fiscalPeriod;
    }
}
