<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\Finance\AccountTypeController;
use App\Http\Controllers\Api\V1\Finance\ChartOfAccountController;
use App\Http\Controllers\Api\V1\Finance\FiscalYearController;
use App\Http\Controllers\Api\V1\Finance\FiscalPeriodController;
use App\Http\Controllers\Api\V1\Finance\ExchangeRateController;
use App\Http\Controllers\Api\V1\Finance\TaxController;
use App\Http\Controllers\Api\V1\Finance\PaymentTermController;
use App\Http\Controllers\Api\V1\Finance\CashRegisterController;
use App\Http\Controllers\Api\V1\Finance\BankAccountController;
use App\Domains\Finance\Controllers\ManualJournalController;
use App\Domains\Finance\Controllers\ManualJournalController;
use App\Domains\Finance\Controllers\AccountMappingController;
use App\Domains\Finance\Controllers\Api\V1\PaymentController;

Route::middleware('auth:sanctum')->group(function () {
    
    // Account Types Routes
    Route::prefix('account-types')->group(function () {
        Route::get('/', [AccountTypeController::class, 'index'])->name('account-types.index');
        Route::get('/{id}', [AccountTypeController::class, 'show'])->name('account-types.show');
    });

    // Chart Of Accounts Routes
    Route::prefix('chart-of-accounts')->group(function () {
        Route::get('/tree', [ChartOfAccountController::class, 'tree'])->name('chart-of-accounts.tree');
        Route::get('/search', [ChartOfAccountController::class, 'search'])->name('chart-of-accounts.search');
        Route::get('/', [ChartOfAccountController::class, 'index'])->name('chart-of-accounts.index');
        Route::post('/', [ChartOfAccountController::class, 'store'])->name('chart-of-accounts.store');
        Route::get('/{id}', [ChartOfAccountController::class, 'show'])->name('chart-of-accounts.show');
        Route::put('/{id}', [ChartOfAccountController::class, 'update'])->name('chart-of-accounts.update');
        Route::delete('/{id}', [ChartOfAccountController::class, 'destroy'])->name('chart-of-accounts.destroy');
        Route::post('/{id}/activate', [ChartOfAccountController::class, 'activate'])->name('chart-of-accounts.activate');
        Route::post('/{id}/deactivate', [ChartOfAccountController::class, 'deactivate'])->name('chart-of-accounts.deactivate');
    });

    // Fiscal Years Routes
    Route::prefix('fiscal-years')->group(function () {
        Route::get('/search', [FiscalYearController::class, 'search'])->name('fiscal-years.search');
        Route::get('/', [FiscalYearController::class, 'index'])->name('fiscal-years.index');
        Route::post('/', [FiscalYearController::class, 'store'])->name('fiscal-years.store');
        Route::get('/{id}', [FiscalYearController::class, 'show'])->name('fiscal-years.show');
        Route::put('/{id}', [FiscalYearController::class, 'update'])->name('fiscal-years.update');
        Route::delete('/{id}', [FiscalYearController::class, 'destroy'])->name('fiscal-years.destroy');
        Route::post('/{id}/close', [FiscalYearController::class, 'close'])->name('fiscal-years.close');
    });

    // Fiscal Periods Routes
    Route::prefix('fiscal-periods')->group(function () {
        Route::get('/search', [FiscalPeriodController::class, 'search'])->name('fiscal-periods.search');
        Route::get('/', [FiscalPeriodController::class, 'index'])->name('fiscal-periods.index');
        Route::post('/', [FiscalPeriodController::class, 'store'])->name('fiscal-periods.store');
        Route::get('/{id}', [FiscalPeriodController::class, 'show'])->name('fiscal-periods.show');
        Route::put('/{id}', [FiscalPeriodController::class, 'update'])->name('fiscal-periods.update');
        Route::delete('/{id}', [FiscalPeriodController::class, 'destroy'])->name('fiscal-periods.destroy');
        Route::post('/{id}/close', [FiscalPeriodController::class, 'close'])->name('fiscal-periods.close');
    });

    // Exchange Rates Routes
    Route::prefix('exchange-rates')->group(function () {
        Route::get('/search', [ExchangeRateController::class, 'search'])->name('exchange-rates.search');
        Route::get('/', [ExchangeRateController::class, 'index'])->name('exchange-rates.index');
        Route::post('/', [ExchangeRateController::class, 'store'])->name('exchange-rates.store');
        Route::get('/{id}', [ExchangeRateController::class, 'show'])->name('exchange-rates.show');
        Route::put('/{id}', [ExchangeRateController::class, 'update'])->name('exchange-rates.update');
        Route::delete('/{id}', [ExchangeRateController::class, 'destroy'])->name('exchange-rates.destroy');
    });

    // Taxes Routes
    Route::prefix('taxes')->group(function () {
        Route::get('/search', [TaxController::class, 'search'])->name('taxes.search');
        Route::get('/', [TaxController::class, 'index'])->name('taxes.index');
        Route::post('/', [TaxController::class, 'store'])->name('taxes.store');
        Route::get('/{id}', [TaxController::class, 'show'])->name('taxes.show');
        Route::put('/{id}', [TaxController::class, 'update'])->name('taxes.update');
        Route::post('/{id}/activate', [TaxController::class, 'activate'])->name('taxes.activate');
        Route::post('/{id}/deactivate', [TaxController::class, 'deactivate'])->name('taxes.deactivate');
        Route::delete('/{id}', [TaxController::class, 'destroy'])->name('taxes.destroy');
    });

    // Payment Terms Routes
    Route::prefix('payment-terms')->group(function () {
        Route::get('/search', [PaymentTermController::class, 'search'])->name('payment-terms.search');
        Route::get('/', [PaymentTermController::class, 'index'])->name('payment-terms.index');
        Route::post('/', [PaymentTermController::class, 'store'])->name('payment-terms.store');
        Route::get('/{id}', [PaymentTermController::class, 'show'])->name('payment-terms.show');
        Route::put('/{id}', [PaymentTermController::class, 'update'])->name('payment-terms.update');
        Route::post('/{id}/activate', [PaymentTermController::class, 'activate'])->name('payment-terms.activate');
        Route::post('/{id}/deactivate', [PaymentTermController::class, 'deactivate'])->name('payment-terms.deactivate');
        Route::delete('/{id}', [PaymentTermController::class, 'destroy'])->name('payment-terms.destroy');
    });

    // Cash Registers Routes
    Route::prefix('cash-registers')->group(function () {
        Route::get('/search', [CashRegisterController::class, 'search'])->name('cash-registers.search');
        Route::get('/', [CashRegisterController::class, 'index'])->name('cash-registers.index');
        Route::post('/', [CashRegisterController::class, 'store'])->name('cash-registers.store');
        Route::get('/{id}', [CashRegisterController::class, 'show'])->name('cash-registers.show');
        Route::put('/{id}', [CashRegisterController::class, 'update'])->name('cash-registers.update');
        Route::post('/{id}/activate', [CashRegisterController::class, 'activate'])->name('cash-registers.activate');
        Route::post('/{id}/deactivate', [CashRegisterController::class, 'deactivate'])->name('cash-registers.deactivate');
        Route::delete('/{id}', [CashRegisterController::class, 'destroy'])->name('cash-registers.destroy');
    });

    // Bank Accounts Routes
    Route::prefix('bank-accounts')->group(function () {
        Route::get('/search', [BankAccountController::class, 'search'])->name('bank-accounts.search');
        Route::get('/', [BankAccountController::class, 'index'])->name('bank-accounts.index');
        Route::post('/', [BankAccountController::class, 'store'])->name('bank-accounts.store');
        Route::get('/{id}', [BankAccountController::class, 'show'])->name('bank-accounts.show');
        Route::put('/{id}', [BankAccountController::class, 'update'])->name('bank-accounts.update');
        Route::post('/{id}/activate', [BankAccountController::class, 'activate'])->name('bank-accounts.activate');
        Route::post('/{id}/deactivate', [BankAccountController::class, 'deactivate'])->name('bank-accounts.deactivate');
        Route::delete('/{id}', [BankAccountController::class, 'destroy'])->name('bank-accounts.destroy');
    });

    // Manual Journals Routes
    Route::prefix('manual-journals')->group(function () {
        Route::post('/', [ManualJournalController::class, 'store'])->name('manual-journals.store');
        Route::get('/{id}', [ManualJournalController::class, 'show'])->name('manual-journals.show');
        Route::post('/{id}/reverse', [ManualJournalController::class, 'reverse'])->name('manual-journals.reverse');
    });

    // Account Mappings Routes
    Route::prefix('account-mappings')->group(function () {
        Route::get('/', [AccountMappingController::class, 'index'])->name('account-mappings.index');
        Route::post('/', [AccountMappingController::class, 'store'])->name('account-mappings.store');
        Route::get('/{businessId}/{mappingType}', [AccountMappingController::class, 'show'])->name('account-mappings.show');
        Route::put('/{businessId}/{mappingType}', [AccountMappingController::class, 'update'])->name('account-mappings.update');
        Route::delete('/{businessId}/{mappingType}', [AccountMappingController::class, 'destroy'])->name('account-mappings.destroy');
    });

    // Payments Routes
    Route::prefix('payments')->group(function () {
        Route::get('/', [PaymentController::class, 'index'])->name('payments.index');
        Route::post('/', [PaymentController::class, 'store'])->name('payments.store');
        Route::get('/{payment}', [PaymentController::class, 'show'])->name('payments.show');
        Route::put('/{payment}', [PaymentController::class, 'update'])->name('payments.update');
        Route::delete('/{payment}', [PaymentController::class, 'destroy'])->name('payments.destroy');
        Route::post('/{payment}/post', [PaymentController::class, 'post'])->name('payments.post');
        Route::post('/{payment}/reverse', [PaymentController::class, 'reverse'])->name('payments.reverse');
    });

});

