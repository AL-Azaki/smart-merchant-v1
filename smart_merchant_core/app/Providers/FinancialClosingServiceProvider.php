<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use App\Domains\FinancialClosing\Repositories\Eloquent\AccountingPeriodEloquentRepository;

class FinancialClosingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            AccountingPeriodRepositoryInterface::class,
            AccountingPeriodEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
