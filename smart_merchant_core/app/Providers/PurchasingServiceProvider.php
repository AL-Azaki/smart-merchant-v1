<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Purchasing\Repositories\Contracts\PurchaseInvoiceRepositoryInterface;
use App\Domains\Purchasing\Repositories\Eloquent\PurchaseInvoiceEloquentRepository;

class PurchasingServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->app->bind(
            PurchaseInvoiceRepositoryInterface::class,
            PurchaseInvoiceEloquentRepository::class
        );
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }
}
