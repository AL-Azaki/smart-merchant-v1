<?php

use Illuminate\Support\Facades\Route;
use App\Domains\Inventory\Http\Controllers\InventoryTransactionController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('inventory-transactions', InventoryTransactionController::class);
});
