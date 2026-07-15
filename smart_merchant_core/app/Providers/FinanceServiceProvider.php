<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\AccountTypeEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\ChartOfAccountRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\ChartOfAccountEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\FiscalYearEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\FiscalPeriodEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\ExchangeRateRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\ExchangeRateEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\TaxEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\PaymentTermRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\PaymentTermEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\CashRegisterEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\BankAccountEloquentRepository;
use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Repositories\Eloquent\PaymentEloquentRepository;

class FinanceServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            AccountTypeRepositoryInterface::class,
            AccountTypeEloquentRepository::class
        );
        
        $this->app->bind(
            ChartOfAccountRepositoryInterface::class,
            ChartOfAccountEloquentRepository::class
        );

        $this->app->bind(
            FiscalYearRepositoryInterface::class,
            FiscalYearEloquentRepository::class
        );

        $this->app->bind(
            FiscalPeriodRepositoryInterface::class,
            FiscalPeriodEloquentRepository::class
        );

        $this->app->bind(
            ExchangeRateRepositoryInterface::class,
            ExchangeRateEloquentRepository::class
        );

        $this->app->bind(
            TaxRepositoryInterface::class,
            TaxEloquentRepository::class
        );

        $this->app->bind(
            PaymentTermRepositoryInterface::class,
            PaymentTermEloquentRepository::class
        );

        $this->app->bind(
            CashRegisterRepositoryInterface::class,
            CashRegisterEloquentRepository::class
        );

        $this->app->bind(
            BankAccountRepositoryInterface::class,
            BankAccountEloquentRepository::class
        );

        $this->app->bind(
            PaymentRepositoryInterface::class,
            PaymentEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
