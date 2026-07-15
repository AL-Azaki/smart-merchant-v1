<?php

namespace App\Domains\Core\Actions\Currency;

use App\Models\Core\Currency;
use App\Domains\Core\DTOs\ViewCurrencyDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(ViewCurrencyDTO $dto): Currency
    {
        $currency = $this->repository->findById($dto->currencyId);

        if (!$currency) {
            throw new CoreDomainException("The specified currency does not exist.");
        }

        return $currency;
    }
}
