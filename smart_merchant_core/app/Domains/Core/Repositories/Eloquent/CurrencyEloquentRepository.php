<?php

namespace App\Domains\Core\Repositories\Eloquent;

use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\Business;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\DTOs\CurrencyListCriteriaDTO;
use App\Domains\Core\DTOs\CurrencySearchCriteriaDTO;
use App\Domains\Core\DTOs\UpdateCurrencyDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class CurrencyEloquentRepository implements CurrencyRepositoryInterface
{
    public function create(array $data): Currency
    {
        return Currency::create($data);
    }

    public function findById(string $id): ?Currency
    {
        return Currency::find($id);
    }

    public function existsByCode(string $code): bool
    {
        return Currency::where('code', strtoupper($code))->exists();
    }

    public function paginate(CurrencyListCriteriaDTO $criteria): LengthAwarePaginator
    {
        return Currency::orderBy($criteria->sortField, $criteria->sortDir)
            ->paginate($criteria->perPage);
    }

    public function search(CurrencySearchCriteriaDTO $criteria): LengthAwarePaginator
    {
        $query = Currency::query();

        if (!empty($criteria->keyword)) {
            $query->where(function ($q) use ($criteria) {
                $q->where('name', 'like', "%{$criteria->keyword}%")
                  ->orWhere('code', 'like', "%{$criteria->keyword}%");
            });
        }

        if ($criteria->isActive !== null) {
            $query->where('is_active', $criteria->isActive);
        }

        return $query->orderBy($criteria->sortField, $criteria->sortDir)
                     ->paginate($criteria->perPage);
    }

    public function update(Currency $currency, UpdateCurrencyDTO $dto): Currency
    {
        $currency->update($dto->toArray());
        return $currency;
    }

    public function delete(Currency $currency): bool
    {
        return (bool) $currency->delete();
    }

    public function updateStatus(Currency $currency, bool $isActive): Currency
    {
        $currency->update(['is_active' => $isActive]);
        return $currency;
    }

    public function setAsDefault(Currency $currency): Currency
    {
        DB::transaction(function () use ($currency) {
            // Unset current default
            Currency::where('is_default', true)->update(['is_default' => false]);
            // Set new default
            $currency->update(['is_default' => true]);
        });

        return $currency->refresh();
    }

    public function isUsed(Currency $currency): bool
    {
        // @todo: Add checks for Invoices, Payments, Journal Entries when Finance Domain is built.
        // Currently checking if any Business uses it as base_currency.
        return Business::where('base_currency_id', $currency->id)->exists();
    }
}
