<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\Models\Currency;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class DeactivateCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(Currency $currency): Currency
    {
        if ($currency->is_default) {
            throw new CoreDomainException("Cannot deactivate the default system currency. Set another currency as default first.");
        }

        if (!$currency->is_active) {
            return $currency;
        }

        return $this->repository->updateStatus($currency, false);
    }
}
