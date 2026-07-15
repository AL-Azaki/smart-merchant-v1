<?php

use Illuminate\Support\Facades\Route;
use App\Domains\Sales\Http\Controllers\SalesInvoiceController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('sales-invoices', SalesInvoiceController::class);
});
