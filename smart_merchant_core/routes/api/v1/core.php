<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\Core\CurrencyController;
use App\Http\Controllers\Api\V1\Core\BusinessController;
use App\Http\Controllers\Api\V1\Core\BranchController;
use App\Http\Controllers\Api\V1\Core\UserController;
use App\Http\Controllers\Api\V1\Core\PermissionController;
use App\Http\Controllers\Api\V1\Core\RoleController;
use App\Http\Controllers\Api\V1\Core\AccountController;

Route::prefix('core')->group(function () {
    // Currencies (Reference Master Data)
    Route::get('currencies/search', [CurrencyController::class, 'search']);
    Route::get('currencies', [CurrencyController::class, 'index']);
    Route::post('currencies', [CurrencyController::class, 'store']);
    Route::get('currencies/{id}', [CurrencyController::class, 'show']);
    Route::patch('currencies/{id}', [CurrencyController::class, 'update']);
    Route::delete('currencies/{id}', [CurrencyController::class, 'destroy']);
    Route::patch('currencies/{id}/activate', [CurrencyController::class, 'activate']);
    Route::patch('currencies/{id}/deactivate', [CurrencyController::class, 'deactivate']);
    Route::patch('currencies/{id}/set-default', [CurrencyController::class, 'setDefault']);

    // Plans (Reference Master Data)
    Route::get('plans/search', [PlanController::class, 'search']);
    Route::get('plans', [PlanController::class, 'index']);
    Route::post('plans', [PlanController::class, 'store']);
    Route::get('plans/{id}', [PlanController::class, 'show']);
    Route::patch('plans/{id}', [PlanController::class, 'update']);
    Route::delete('plans/{id}', [PlanController::class, 'destroy']);
    Route::patch('plans/{id}/activate', [PlanController::class, 'activate']);
    Route::patch('plans/{id}/deactivate', [PlanController::class, 'deactivate']);

    // Accounts (Tenant Root)
    Route::get('accounts/search', [AccountController::class, 'search']);
    Route::get('accounts', [AccountController::class, 'index']);
    Route::post('accounts', [AccountController::class, 'store']);
    Route::get('accounts/{id}', [AccountController::class, 'show']);
    Route::patch('accounts/{id}', [AccountController::class, 'update']);
    Route::patch('accounts/{id}/suspend', [AccountController::class, 'suspend']);
    Route::patch('accounts/{id}/activate', [AccountController::class, 'activate']);
    Route::patch('accounts/{id}/close', [AccountController::class, 'close']);

    // Subscriptions (Nested under Account)
    Route::prefix('accounts/{account_id}/subscriptions')->group(function () {
        Route::get('search', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'search']);
        Route::get('/', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'index']);
        Route::post('/', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'store']);
        Route::get('{id}', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'show']);
        Route::patch('{id}/activate', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'activate']);
        Route::patch('{id}/suspend', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'suspend']);
        Route::patch('{id}/cancel', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'cancel']);
        Route::patch('{id}/expire', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'expire']);
        Route::patch('{id}/close', [\App\Http\Controllers\Api\V1\Core\SubscriptionController::class, 'close']);
    });

    // Subscription Payments (Nested under Subscription)
    Route::prefix('subscriptions/{subscription_id}/payments')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\V1\Core\SubscriptionPaymentController::class, 'index']);
        Route::post('/', [\App\Http\Controllers\Api\V1\Core\SubscriptionPaymentController::class, 'store']);
        Route::get('{id}', [\App\Http\Controllers\Api\V1\Core\SubscriptionPaymentController::class, 'show']);
        Route::patch('{id}/succeed', [\App\Http\Controllers\Api\V1\Core\SubscriptionPaymentController::class, 'markAsSucceeded']);
        Route::patch('{id}/fail', [\App\Http\Controllers\Api\V1\Core\SubscriptionPaymentController::class, 'markAsFailed']);
    });

    Route::post('businesses', [BusinessController::class, 'store']);

    // Permissions (System Catalog - Read Only)
    Route::get('permissions/search', [PermissionController::class, 'search']);
    Route::get('permissions', [PermissionController::class, 'index']);
    Route::get('permissions/{id}', [PermissionController::class, 'show']);

    // Roles
    Route::get('roles/search', [RoleController::class, 'search']);
    Route::get('roles', [RoleController::class, 'index']);
    Route::post('roles', [RoleController::class, 'store']);
    Route::get('roles/{id}', [RoleController::class, 'show']);
    Route::patch('roles/{id}', [RoleController::class, 'update']);
    Route::delete('roles/{id}', [RoleController::class, 'destroy']);
    Route::patch('roles/{id}/permissions', [RoleController::class, 'syncPermissions']);

    // Branches
    Route::get('branches/search', [BranchController::class, 'search']);
    Route::get('branches', [BranchController::class, 'index']);
    Route::post('branches', [BranchController::class, 'store']);
    Route::get('branches/{id}', [BranchController::class, 'show']);
    Route::patch('branches/{id}', [BranchController::class, 'update']);
    Route::patch('branches/{id}/set-default', [BranchController::class, 'setDefault']);
    Route::patch('branches/{id}/activate', [BranchController::class, 'activate']);
    Route::patch('branches/{id}/deactivate', [BranchController::class, 'deactivate']);
    Route::delete('branches/{id}', [BranchController::class, 'destroy']);

    // Users
    Route::get('users/search', [UserController::class, 'search']);
    Route::get('users', [UserController::class, 'index']);
    Route::post('users', [UserController::class, 'store']);
    Route::get('users/{id}', [UserController::class, 'show']);
    Route::patch('users/{id}', [UserController::class, 'update']);
    Route::patch('users/{id}/suspend', [UserController::class, 'suspend']);
    Route::patch('users/{id}/activate', [UserController::class, 'activate']);
    Route::patch('users/{id}/roles', [UserController::class, 'syncRoles']);
    Route::patch('users/{id}/branches', [UserController::class, 'syncBranches']);
});
