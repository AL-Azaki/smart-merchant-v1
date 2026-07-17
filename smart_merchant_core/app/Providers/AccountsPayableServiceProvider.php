<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use App\Domains\AccountsPayable\Repositories\Eloquent\SupplierPayableEloquentRepository;

class AccountsPayableServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            SupplierPayableRepositoryInterface::class,
            SupplierPayableEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
