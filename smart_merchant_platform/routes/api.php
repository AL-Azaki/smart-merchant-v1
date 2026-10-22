<?php

use App\Http\Controllers\Api\Admin\AdminBranchController;
use App\Http\Controllers\Api\Admin\AdminBusinessController;
use App\Http\Controllers\Api\Admin\AdminBusinessUserController;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminDeviceController;
use App\Http\Controllers\Api\Admin\AdminOrderController;
use App\Http\Controllers\Api\Admin\AdminRoleController;
use App\Http\Controllers\Api\Admin\AdminSubscriptionController;
use App\Http\Controllers\Api\Admin\AdminUserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusinessSetupController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\MarketplaceController;
use App\Http\Controllers\Api\Media\MediaController;
use App\Http\Controllers\Api\Platform\StorefrontSettingsController;
use App\Http\Controllers\Api\SessionBootstrapController;
use App\Http\Controllers\Api\StorefrontController;
use App\Http\Controllers\Sync\SyncController;
use App\Http\Middleware\AuthorizeBusinessAdmin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

/*
|--------------------------------------------------------------------------
| Authentication & Authorization API
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('business/setup', [BusinessSetupController::class, 'completeSetup']);
});

/*
|--------------------------------------------------------------------------
| Platform Management API (Accounts, Businesses, Subscriptions)
|--------------------------------------------------------------------------
*/
Route::prefix('platform')->middleware('auth:sanctum')->group(function () {
    Route::get('storefront/settings', [StorefrontSettingsController::class, 'show']);
    Route::put('storefront/settings', [StorefrontSettingsController::class, 'update']);
    Route::get('storefront/slug-availability', [StorefrontSettingsController::class, 'checkSlugAvailability']);
});

Route::prefix('media')->middleware('auth:sanctum')->group(function () {
    Route::post('/product-image', [MediaController::class, 'uploadProductImage']);
});

/*
|--------------------------------------------------------------------------
| Sync Gateway API
|--------------------------------------------------------------------------
| Entry points for receiving and pushing synchronization payloads with Flutter clients.
*/
Route::prefix('sync')->middleware('auth:sanctum')->group(function () {
    Route::post('/push', [SyncController::class, 'push']);
    Route::post('/pull', [SyncController::class, 'pull']);
    Route::post('/ack', [SyncController::class, 'ack']);
    Route::post('/orders/{order}/status', [SyncController::class, 'updateOrderStatus']);
});

Route::prefix('session')->middleware('auth:sanctum')->group(function () {
    Route::get('/bootstrap', [SessionBootstrapController::class, 'bootstrap']);
});

Route::prefix('devices')->middleware('auth:sanctum')->group(function () {
    Route::post('/register', [DeviceController::class, 'register']);
});

/*
|--------------------------------------------------------------------------
| Central Marketplace Public API (Home Exploration & Omnisearch)
|--------------------------------------------------------------------------
*/
Route::prefix('marketplace/v1')->group(function () {
    Route::get('explore', [MarketplaceController::class, 'explore']);
});

/*
|--------------------------------------------------------------------------
| Storefront Public API
|--------------------------------------------------------------------------
| Customer-facing endpoints for Next.js Storefront.
*/
Route::prefix('storefront/v1')->group(function () {
    Route::get('{store}/bootstrap', [StorefrontController::class, 'bootstrap']);
    Route::get('{store}/categories', [StorefrontController::class, 'categories']);
    Route::get('{store}/products', [StorefrontController::class, 'products']);
    Route::get('{store}/products/{product}', [StorefrontController::class, 'productDetail']);
    Route::post('{store}/orders', [StorefrontController::class, 'createOrder'])->middleware('throttle:10,1');
});

// Admin / Management API
Route::prefix('admin/v1')->middleware(['auth:sanctum', 'throttle:120,1'])->group(function () {
    Route::get('me', [AdminUserController::class, 'me']);
    Route::get('dashboard', [AdminDashboardController::class, 'index']);

    // Accounts management & approval
    Route::apiResource('accounts', \App\Http\Controllers\Api\Admin\AdminAccountController::class)->only(['index', 'show', 'store', 'update']);
    Route::post('accounts/{account}/approve', [\App\Http\Controllers\Api\Admin\AdminAccountController::class, 'approve']);
    Route::post('accounts/{account}/suspend', [\App\Http\Controllers\Api\Admin\AdminAccountController::class, 'suspend']);
    Route::post('accounts/{account}/reactivate', [\App\Http\Controllers\Api\Admin\AdminAccountController::class, 'reactivate']);

    // Platform users
    Route::get('users', [AdminUserController::class, 'index']);
    Route::put('users/{user}', [AdminUserController::class, 'update']);

    Route::apiResource('businesses', AdminBusinessController::class)->only(['index', 'show', 'store', 'update']);

    Route::prefix('businesses/{business}')->middleware(AuthorizeBusinessAdmin::class)->group(function () {
        Route::apiResource('branches', AdminBranchController::class)->only(['index', 'show', 'store', 'update']);
        Route::apiResource('users', AdminBusinessUserController::class)->only(['index', 'show', 'store', 'update']);
        Route::apiResource('roles', AdminRoleController::class)->only(['index', 'show']);
        Route::apiResource('devices', AdminDeviceController::class)->only(['index', 'show', 'update', 'destroy']);
        Route::apiResource('orders', AdminOrderController::class)->only(['index', 'show']);
        Route::apiResource('subscriptions', AdminSubscriptionController::class)->only(['index', 'show', 'update']);
    });
});

