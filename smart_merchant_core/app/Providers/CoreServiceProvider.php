<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\BranchRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\BusinessRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\CurrencyRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\PermissionRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\PlanRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\RoleRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\SubscriptionPaymentRepositoryInterface;
use App\Domains\Core\Repositories\Contracts\UserRepositoryInterface;

use App\Domains\Extended\Repositories\Contracts\SystemSettingRepositoryInterface;
use App\Domains\Extended\Repositories\Contracts\PrintSettingRepositoryInterface;

use App\Domains\Core\Repositories\Eloquent\AccountEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\BranchEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\BusinessEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\CurrencyEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\PermissionEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\PlanEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\RoleEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\SubscriptionEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\SubscriptionPaymentEloquentRepository;
use App\Domains\Core\Repositories\Eloquent\UserEloquentRepository;
use App\Domains\Extended\Repositories\Eloquent\SystemSettingEloquentRepository;
use App\Domains\Extended\Repositories\Eloquent\PrintSettingEloquentRepository;

class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(AccountRepositoryInterface::class, AccountEloquentRepository::class);
        $this->app->bind(BranchRepositoryInterface::class, BranchEloquentRepository::class);
        $this->app->bind(BusinessRepositoryInterface::class, BusinessEloquentRepository::class);
        $this->app->bind(CurrencyRepositoryInterface::class, CurrencyEloquentRepository::class);
        $this->app->bind(PermissionRepositoryInterface::class, PermissionEloquentRepository::class);
        $this->app->bind(PlanRepositoryInterface::class, PlanEloquentRepository::class);
        $this->app->bind(RoleRepositoryInterface::class, RoleEloquentRepository::class);
        $this->app->bind(SubscriptionRepositoryInterface::class, SubscriptionEloquentRepository::class);
        $this->app->bind(SubscriptionPaymentRepositoryInterface::class, SubscriptionPaymentEloquentRepository::class);
        $this->app->bind(UserRepositoryInterface::class, UserEloquentRepository::class);
        $this->app->bind(SystemSettingRepositoryInterface::class, SystemSettingEloquentRepository::class);
        $this->app->bind(PrintSettingRepositoryInterface::class, PrintSettingEloquentRepository::class);
    }

    public function boot(): void
    {
        //
    }
}
