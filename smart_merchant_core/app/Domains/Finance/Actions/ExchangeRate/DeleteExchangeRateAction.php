<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class DeleteExchangeRateAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(string $exchangeRateId, string $businessId): bool
    {
        $exchangeRate = $this->repository->findById($exchangeRateId);

        if (!$exchangeRate || $exchangeRate->business_id !== $businessId) {
            throw new ModelNotFoundException("Exchange rate not found.");
        }

        if ($this->repository->isUsedInJournalEntries($exchangeRate->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot delete an exchange rate that has been used in journal entries. It must be kept for audit trail purposes.'
            ]);
        }

        return $this->repository->delete($exchangeRate);
    }
}
