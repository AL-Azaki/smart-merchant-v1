<?php

namespace App\Domains\Finance\Actions\ExchangeRate;

use App\Domains\Finance\DTOs\UpdateExchangeRateDTO;
use App\Domains\Finance\Models\ExchangeRate;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class UpdateExchangeRateAction
{
    public function __construct(private readonly ExchangeRateRepositoryInterface $repository) {}

    public function handle(UpdateExchangeRateDTO $dto): ExchangeRate
    {
        $exchangeRate = $this->repository->findById($dto->exchangeRateId);

        if (!$exchangeRate || $exchangeRate->business_id !== $dto->businessId) {
            throw new ModelNotFoundException("Exchange rate not found.");
        }

        // Update Protection Rule:
        // إذا تم استخدام ExchangeRate في أي عملية تشغيلية أو تم أخذ Snapshot منه داخل JournalEntry:
        // يمنع التعديل ويصبح السجل للقراءة فقط
        if ($this->repository->isUsedInJournalEntries($exchangeRate->id)) {
            throw ValidationException::withMessages([
                'id' => 'Cannot update an exchange rate that has been used in journal entries. It is read-only.'
            ]);
        }

        // Validate Temporal Uniqueness if changing currencies or date
        if (
            $exchangeRate->source_currency_id !== $dto->sourceCurrencyId ||
            $exchangeRate->target_currency_id !== $dto->targetCurrencyId ||
            $exchangeRate->effective_date->format('Y-m-d') !== $dto->effectiveDate
        ) {
            $existing = $this->repository->findExactRate($dto->businessId, $dto->sourceCurrencyId, $dto->targetCurrencyId, $dto->effectiveDate);
            if ($existing && $existing->id !== $exchangeRate->id) {
                throw ValidationException::withMessages([
                    'effective_date' => 'An exchange rate for these currencies already exists on this date.'
                ]);
            }
        }

        $data = [
            'source_currency_id' => $dto->sourceCurrencyId,
            'target_currency_id' => $dto->targetCurrencyId,
            'effective_date' => $dto->effectiveDate,
            'rate' => $dto->rate,
        ];

        return $this->repository->update($exchangeRate, $data);
    }
}
