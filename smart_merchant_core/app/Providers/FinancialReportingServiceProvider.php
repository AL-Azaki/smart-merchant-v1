<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\FinancialReporting\Repositories\Contracts\ReportingDataRepositoryInterface;
use App\Domains\FinancialReporting\Repositories\Eloquent\ReportingDataEloquentRepository;

class FinancialReportingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            ReportingDataRepositoryInterface::class,
            ReportingDataEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
