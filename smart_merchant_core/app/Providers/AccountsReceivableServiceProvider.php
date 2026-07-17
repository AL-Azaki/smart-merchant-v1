<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use App\Domains\AccountsReceivable\Repositories\Eloquent\CustomerReceivableEloquentRepository;

class AccountsReceivableServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            CustomerReceivableRepositoryInterface::class,
            CustomerReceivableEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
