<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\SessionBootstrapController;
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
    Route::post('business/setup', [\App\Http\Controllers\Api\BusinessSetupController::class, 'completeSetup']);
});

/*
|--------------------------------------------------------------------------
| Platform Management API (Accounts, Businesses, Subscriptions)
|--------------------------------------------------------------------------
*/
Route::prefix('platform')->middleware('auth:sanctum')->group(function () {
    // Accounts, Businesses, Branches, and Subscriptions endpoints will be registered here.
});

/*
|--------------------------------------------------------------------------
| Sync Gateway API
|--------------------------------------------------------------------------
| Entry points for receiving and pushing synchronization payloads with Flutter clients.
*/
Route::prefix('sync')->middleware('auth:sanctum')->group(function () {
    Route::post('/push', [\App\Http\Controllers\Sync\SyncController::class, 'push']);
    Route::post('/pull', [\App\Http\Controllers\Sync\SyncController::class, 'pull']);
    Route::post('/ack', [\App\Http\Controllers\Sync\SyncController::class, 'ack']);
});

Route::prefix('session')->middleware('auth:sanctum')->group(function () {
    Route::get('/bootstrap', [SessionBootstrapController::class, 'bootstrap']);
});

Route::prefix('devices')->middleware('auth:sanctum')->group(function () {
    Route::post('/register', [DeviceController::class, 'register']);
});

/*
|--------------------------------------------------------------------------
| Storefront Public API
|--------------------------------------------------------------------------
| Customer-facing endpoints for React Storefront.
*/
Route::prefix('storefront/v1')->group(function () {
    Route::get('{store}/bootstrap', [\App\Http\Controllers\Api\StorefrontController::class, 'bootstrap']);
    Route::get('{store}/categories', [\App\Http\Controllers\Api\StorefrontController::class, 'categories']);
    Route::get('{store}/products', [\App\Http\Controllers\Api\StorefrontController::class, 'products']);
    Route::get('{store}/products/{product}', [\App\Http\Controllers\Api\StorefrontController::class, 'productDetail']);
    Route::post('{store}/orders', [\App\Http\Controllers\Api\StorefrontController::class, 'createOrder'])->middleware('throttle:10,1');
});

// Admin / Management API
Route::prefix('admin/v1')->middleware(['auth:sanctum', 'throttle:10,1'])->group(function () {
    Route::get('me', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'me']);
    Route::get('dashboard', [\App\Http\Controllers\Api\Admin\AdminDashboardController::class, 'index']);

    Route::apiResource('businesses', \App\Http\Controllers\Api\Admin\AdminBusinessController::class)->only(['index', 'show', 'store', 'update']);
    
    Route::prefix('businesses/{business}')->middleware(\App\Http\Middleware\AuthorizeBusinessAdmin::class)->group(function () {
        Route::apiResource('branches', \App\Http\Controllers\Api\Admin\AdminBranchController::class)->only(['index', 'show', 'store', 'update']);
        Route::apiResource('users', \App\Http\Controllers\Api\Admin\AdminBusinessUserController::class)->only(['index', 'show', 'store', 'update']);
        Route::apiResource('roles', \App\Http\Controllers\Api\Admin\AdminRoleController::class)->only(['index', 'show']);
        Route::apiResource('devices', \App\Http\Controllers\Api\Admin\AdminDeviceController::class)->only(['index', 'show', 'update', 'destroy']);
        Route::apiResource('orders', \App\Http\Controllers\Api\Admin\AdminOrderController::class)->only(['index', 'show']);
        Route::apiResource('subscriptions', \App\Http\Controllers\Api\Admin\AdminSubscriptionController::class)->only(['index', 'show', 'update']);
    });
});
