<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\FixedAssets\Repositories\Contracts\FixedAssetRepositoryInterface;
use App\Domains\FixedAssets\Repositories\Eloquent\FixedAssetEloquentRepository;

class FixedAssetsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            FixedAssetRepositoryInterface::class,
            FixedAssetEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
