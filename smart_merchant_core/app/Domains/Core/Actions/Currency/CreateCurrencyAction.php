<?php

namespace App\Domains\Core\Actions\Currency;

use App\Models\Core\Currency;
use App\Domains\Core\DTOs\CreateCurrencyDTO;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateCurrencyAction
{
    public function __construct(private readonly CurrencyRepositoryInterface $repository) {}

    public function handle(CreateCurrencyDTO $dto): Currency
    {
        if ($this->repository->existsByCode($dto->code)) {
            throw new CoreDomainException("Currency code '{$dto->code}' already exists.");
        }

        return $this->repository->create([
            'name'          => $dto->name,
            'code'          => $dto->code,
            'symbol'        => $dto->symbol,
            'exchange_rate' => $dto->exchangeRate,
            'is_default'    => false,
            'is_active'     => true,
        ]);
    }
}
