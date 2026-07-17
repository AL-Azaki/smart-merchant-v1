<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\Models\Currency;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class SetDefaultCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(Currency $currency): Currency
    {
        if (!$currency->is_active) {
            throw new CoreDomainException("Cannot set an inactive currency as the default system currency.");
        }

        if ($currency->is_default) {
            return $currency;
        }

        return $this->repository->setAsDefault($currency);
    }
}
