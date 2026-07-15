<?php

namespace App\Domains\Core\Actions\Currency;

use App\Models\Core\Currency;
use App\Domains\Core\DTOs\UpdateCurrencyDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(string $currencyId, UpdateCurrencyDTO $dto): Currency
    {
        $currency = $this->repository->findById($currencyId);

        if (!$currency) {
            throw new CoreDomainException("The specified currency does not exist.");
        }

        // Note: Currency code is intentionally omitted from UpdateCurrencyDTO (Immutable Rule).

        return $this->repository->update($currency, $dto);
    }
}
