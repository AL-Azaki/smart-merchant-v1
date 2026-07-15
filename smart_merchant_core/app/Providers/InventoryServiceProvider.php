<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Repositories\Eloquent\InventoryTransactionEloquentRepository;

class InventoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            InventoryTransactionRepositoryInterface::class,
            InventoryTransactionEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
