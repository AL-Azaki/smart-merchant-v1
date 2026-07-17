<?php

namespace App\Domains\Core\Actions\Currency;

use App\Domains\Core\Models\Currency;
use App\Domains\Core\DTOs\UpdateCurrencyDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class UpdateCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(Currency $currency, UpdateCurrencyDTO $dto): Currency
    {
        // Note: Currency code is intentionally omitted from UpdateCurrencyDTO (Immutable Rule).

        return $this->repository->update($currency, $dto);
    }
}
