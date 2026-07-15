<?php

namespace App\Domains\Core\Actions\Currency;

use App\Models\Core\Currency;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ActivateCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(string $currencyId): Currency
    {
        $currency = $this->repository->findById($currencyId);

        if (!$currency) {
            throw new CoreDomainException("The specified currency does not exist.");
        }

        if ($currency->is_active) {
            return $currency;
        }

        return $this->repository->updateStatus($currency, true);
    }
}
