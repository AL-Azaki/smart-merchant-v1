<?php

use Illuminate\Support\Facades\Route;
use App\Domains\Purchasing\Http\Controllers\PurchaseInvoiceController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('purchase-invoices', PurchaseInvoiceController::class);
});
