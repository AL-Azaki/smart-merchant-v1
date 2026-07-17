<?php

namespace App\Domains\Core\Repositories\Contracts;

use App\Domains\Core\Models\Currency;

interface CurrencyRepositoryInterface
{
    public function create(array $data): Currency;

    public function findById(string $id): ?Currency;

    public function existsByCode(string $code): bool;

    public function paginate(\App\Domains\Core\DTOs\CurrencyListCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function search(\App\Domains\Core\DTOs\CurrencySearchCriteriaDTO $criteria): \Illuminate\Contracts\Pagination\LengthAwarePaginator;

    public function update(Currency $currency, \App\Domains\Core\DTOs\UpdateCurrencyDTO $dto): Currency;

    public function delete(Currency $currency): bool;

    public function updateStatus(Currency $currency, bool $isActive): Currency;

    public function setAsDefault(Currency $currency): Currency;

    public function isUsed(Currency $currency): bool;
}
