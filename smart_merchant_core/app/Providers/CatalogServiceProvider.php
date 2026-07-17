<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Catalog\Repositories\Contracts\UnitRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\UnitEloquentRepository;
use App\Domains\Catalog\Repositories\Contracts\CategoryRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\CategoryEloquentRepository;
use App\Domains\Catalog\Repositories\Contracts\ProductRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\ProductEloquentRepository;
use App\Domains\Catalog\Repositories\Contracts\ProductUnitRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\ProductUnitEloquentRepository;
use App\Domains\Catalog\Repositories\Contracts\ProductImageRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\ProductImageEloquentRepository;
use App\Domains\Catalog\Repositories\Contracts\BranchProductPriceRepositoryInterface;
use App\Domains\Catalog\Repositories\Eloquent\BranchProductPriceEloquentRepository;

class CatalogServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            UnitRepositoryInterface::class,
            UnitEloquentRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}




