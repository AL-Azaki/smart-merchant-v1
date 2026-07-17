<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Inventory\Repositories\Contracts\InventoryTransactionRepositoryInterface;
use App\Domains\Inventory\Repositories\Eloquent\InventoryTransactionEloquentRepository;
use App\Domains\Inventory\Repositories\Contracts\WarehouseRepositoryInterface;
use App\Domains\Inventory\Repositories\Eloquent\WarehouseEloquentRepository;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;
use App\Domains\Inventory\Repositories\Eloquent\InventoryEloquentRepository;

class InventoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            InventoryTransactionRepositoryInterface::class,
            InventoryTransactionEloquentRepository::class
        );

        $this->app->bind(
            WarehouseRepositoryInterface::class,
            WarehouseEloquentRepository::class
        );

        $this->app->bind(
            InventoryRepositoryInterface::class,
            InventoryEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}



