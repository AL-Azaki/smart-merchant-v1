<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Sales\Repositories\Contracts\SalesInvoiceRepositoryInterface;
use App\Domains\Sales\Repositories\Eloquent\SalesInvoiceEloquentRepository;

class SalesServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->app->bind(
            SalesInvoiceRepositoryInterface::class,
            SalesInvoiceEloquentRepository::class
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
