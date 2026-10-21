<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('storefront:seed-demo', function () {
    if (app()->environment('production')) {
        $this->error('Refusing to seed demo data in production environment.');
        return 1;
    }

    $this->info('Seeding Storefront demo data...');
    $this->call(\Database\Seeders\StorefrontDevSeeder::class);
    $storeUrl = rtrim(config('storefront.app_url', 'http://localhost:3000'), '/') . '/store/integration-test-store';
    $this->info("Storefront demo ready: {$storeUrl}");
    return 0;
})->purpose('Seed idempotent demo data for the integration test storefront');

