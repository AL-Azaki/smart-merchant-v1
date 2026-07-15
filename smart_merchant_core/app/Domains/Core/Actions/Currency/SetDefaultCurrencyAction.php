<?php

namespace App\Domains\Core\Actions\Currency;

use App\Models\Core\Currency;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class SetDefaultCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(string $currencyId): Currency
    {
        $currency = $this->repository->findById($currencyId);

        if (!$currency) {
            throw new CoreDomainException("The specified currency does not exist.");
        }

        if (!$currency->is_active) {
            throw new CoreDomainException("Cannot set an inactive currency as the default system currency.");
        }

        if ($currency->is_default) {
            return $currency;
        }

        return $this->repository->setAsDefault($currency);
    }
}
