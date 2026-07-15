<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\DTOs\CreateExchangeRateDTO;
use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Validation\ValidationException;

class CreateExchangeRateAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(CreateExchangeRateDTO $dto): ExchangeRate
    {
        // 1. Validate Temporal Uniqueness
        $existing = $this->repository->findExactRate($dto->businessId, $dto->sourceCurrencyId, $dto->targetCurrencyId, $dto->effectiveDate);
        if ($existing) {
            throw ValidationException::withMessages([
                'effective_date' => 'An exchange rate for these currencies already exists on this date.'
            ]);
        }

        $data = [
            'business_id' => $dto->businessId,
            'source_currency_id' => $dto->sourceCurrencyId,
            'target_currency_id' => $dto->targetCurrencyId,
            'effective_date' => $dto->effectiveDate,
            'rate' => $dto->rate,
        ];

        return $this->repository->create($data);
    }
}
