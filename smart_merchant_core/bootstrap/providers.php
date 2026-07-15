<?php

use App\Providers\AppServiceProvider;
use App\Providers\CoreServiceProvider;
use App\Providers\FinanceServiceProvider;
use App\Providers\SalesServiceProvider;
use App\Providers\InventoryServiceProvider;
use App\Providers\PurchasingServiceProvider;

return [
    AppServiceProvider::class,
    CoreServiceProvider::class,
    FinanceServiceProvider::class,
    SalesServiceProvider::class,
    InventoryServiceProvider::class,
    PurchasingServiceProvider::class,
];
