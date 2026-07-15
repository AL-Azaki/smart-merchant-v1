<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\DTOs\ViewExchangeRateDTO;
use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewExchangeRateAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(ViewExchangeRateDTO $dto): ExchangeRate
    {
        $exchangeRate = $this->repository->findById($dto->exchangeRateId);

        if (!$exchangeRate || $exchangeRate->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Exchange rate not found.");
        }

        return $exchangeRate;
    }
}
