<?php

use Illuminate\Support\Facades\Route;
use App\Domains\Inventory\Http\Controllers\InventoryTransactionController;
use App\Http\Controllers\Api\V1\Inventory\WarehouseController;
use App\Http\Controllers\Api\V1\Inventory\InventoryController;

Route::middleware(['auth:sanctum'])->group(function () {
        Route::prefix('inventory-transactions')->group(function () {
        Route::get('/', [InventoryTransactionController::class, 'index']);
        Route::post('/', [InventoryTransactionController::class, 'store']);
        Route::get('/{id}', [InventoryTransactionController::class, 'show']);
        Route::put('/{id}', [InventoryTransactionController::class, 'update']);
        Route::delete('/{id}', [InventoryTransactionController::class, 'destroy']);
        Route::patch('/{id}/post', [InventoryTransactionController::class, 'post']);
        Route::patch('/{id}/reverse', [InventoryTransactionController::class, 'reverse']);
        
        Route::post('/{id}/lines', [InventoryTransactionController::class, 'storeLine']);
        Route::put('/{id}/lines/{lineId}', [InventoryTransactionController::class, 'updateLine']);
        Route::delete('/{id}/lines/{lineId}', [InventoryTransactionController::class, 'destroyLine']);
    });

        Route::prefix('inventories')->group(function () {
        Route::get('/', [InventoryController::class, 'index']);
        Route::get('/search', [InventoryController::class, 'search']);
        Route::post('/', [InventoryController::class, 'store']);
        Route::get('/{id}', [InventoryController::class, 'show']);
        Route::put('/{id}', [InventoryController::class, 'update']);
        Route::delete('/{id}', [InventoryController::class, 'destroy']);
    });

    Route::prefix('warehouses')->group(function () {
        Route::get('/', [WarehouseController::class, 'index']);
        Route::get('/search', [WarehouseController::class, 'search']);
        Route::post('/', [WarehouseController::class, 'store']);
        Route::get('/{id}', [WarehouseController::class, 'show']);
        Route::put('/{id}', [WarehouseController::class, 'update']);
        Route::delete('/{id}', [WarehouseController::class, 'destroy']);
        Route::patch('/{id}/activate', [WarehouseController::class, 'activate']);
        Route::patch('/{id}/deactivate', [WarehouseController::class, 'deactivate']);
    });
});



