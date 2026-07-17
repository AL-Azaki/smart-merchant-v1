<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class DeleteCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(Currency $currency): void
    {
        if ($currency->is_default) {
            throw new CoreDomainException("Cannot delete the default system currency.");
        }

        if ($this->repository->isUsed($currency)) {
            throw new CoreDomainException("Cannot delete currency because it is used in operational entities. Please deactivate it instead.");
        }

        $this->repository->delete($currency);
    }
}
