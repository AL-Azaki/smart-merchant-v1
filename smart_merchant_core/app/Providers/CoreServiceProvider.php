<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Repositories\Eloquent\CurrencyEloquentRepository;

class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            CurrencyRepositoryInterface::class,
            CurrencyEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
