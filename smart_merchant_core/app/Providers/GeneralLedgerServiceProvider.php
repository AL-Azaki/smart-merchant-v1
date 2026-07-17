<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use App\Domains\GeneralLedger\Repositories\Eloquent\JournalEntryEloquentRepository;

class GeneralLedgerServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            JournalEntryRepositoryInterface::class,
            JournalEntryEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
