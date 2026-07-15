<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;
use App\Domains\Sales\Models\SalesInvoice;
use App\Domains\Sales\Policies\SalesInvoicePolicy;
use App\Domains\Inventory\Models\InventoryTransaction;
use App\Domains\Inventory\Policies\InventoryTransactionPolicy;
use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Purchasing\Policies\PurchaseInvoicePolicy;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(SalesInvoice::class, SalesInvoicePolicy::class);
        Gate::policy(InventoryTransaction::class, InventoryTransactionPolicy::class);
        Gate::policy(PurchaseInvoice::class, PurchaseInvoicePolicy::class);
    }
}
