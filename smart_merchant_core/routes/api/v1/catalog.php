<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\V1\Catalog\UnitController;
use App\Http\Controllers\Api\V1\Catalog\CategoryController;
use App\Http\Controllers\Api\V1\Catalog\ProductController;
use App\Http\Controllers\Api\V1\Catalog\ProductUnitController;
use App\Http\Controllers\Api\V1\Catalog\ProductImageController;
use App\Http\Controllers\Api\V1\Catalog\BranchProductPriceController;

Route::middleware('auth:sanctum')->prefix('catalog')->group(function () {
    // Units
    Route::get('units/search', [UnitController::class, 'search']);
    Route::get('units', [UnitController::class, 'index']);
    Route::post('units', [UnitController::class, 'store']);
    Route::get('units/{id}', [UnitController::class, 'show']);
    Route::patch('units/{id}', [UnitController::class, 'update']);
    Route::delete('units/{id}', [UnitController::class, 'destroy']);
    Route::patch('units/{id}/activate', [UnitController::class, 'activate']);
    Route::patch('units/{id}/deactivate', [UnitController::class, 'deactivate']);
    // Categories
    Route::get('categories/search', [CategoryController::class, 'search']);
    Route::get('categories', [CategoryController::class, 'index']);
    Route::post('categories', [CategoryController::class, 'store']);
    Route::get('categories/{id}', [CategoryController::class, 'show']);
    Route::patch('categories/{id}', [CategoryController::class, 'update']);
    Route::delete('categories/{id}', [CategoryController::class, 'destroy']);
    Route::patch('categories/{id}/activate', [CategoryController::class, 'activate']);
    Route::patch('categories/{id}/deactivate', [CategoryController::class, 'deactivate']);

    // Products
    Route::get('products/search', [ProductController::class, 'search']);
    Route::get('products', [ProductController::class, 'index']);
    Route::post('products', [ProductController::class, 'store']);
    Route::get('products/{id}', [ProductController::class, 'show']);
    Route::patch('products/{id}', [ProductController::class, 'update']);
    Route::delete('products/{id}', [ProductController::class, 'destroy']);
    Route::patch('products/{id}/activate', [ProductController::class, 'activate']);
    Route::patch('products/{id}/deactivate', [ProductController::class, 'deactivate']);

    // Product Units
    Route::get('product-units/search', [ProductUnitController::class, 'search']);
    Route::get('product-units', [ProductUnitController::class, 'index']);
    Route::post('product-units', [ProductUnitController::class, 'store']);
    Route::get('product-units/{id}', [ProductUnitController::class, 'show']);
    Route::patch('product-units/{id}', [ProductUnitController::class, 'update']);
    Route::delete('product-units/{id}', [ProductUnitController::class, 'destroy']);
    Route::patch('product-units/{id}/activate', [ProductUnitController::class, 'activate']);
    Route::patch('product-units/{id}/deactivate', [ProductUnitController::class, 'deactivate']);

    // Product Images
    Route::get('product-images/search', [ProductImageController::class, 'search']);
    Route::get('product-images', [ProductImageController::class, 'index']);
    Route::post('product-images', [ProductImageController::class, 'store']);
    Route::get('product-images/{id}', [ProductImageController::class, 'show']);
    Route::patch('product-images/{id}', [ProductImageController::class, 'update']);
    Route::delete('product-images/{id}', [ProductImageController::class, 'destroy']);
    Route::patch('product-images/{id}/activate', [ProductImageController::class, 'activate']);
    Route::patch('product-images/{id}/deactivate', [ProductImageController::class, 'deactivate']);

    // Branch Product Prices
    Route::get('branch-product-prices/search', [BranchProductPriceController::class, 'search']);
    Route::get('branch-product-prices', [BranchProductPriceController::class, 'index']);
    Route::post('branch-product-prices', [BranchProductPriceController::class, 'store']);
    Route::get('branch-product-prices/{id}', [BranchProductPriceController::class, 'show']);
    Route::patch('branch-product-prices/{id}', [BranchProductPriceController::class, 'update']);
    Route::delete('branch-product-prices/{id}', [BranchProductPriceController::class, 'destroy']);
    Route::patch('branch-product-prices/{id}/activate', [BranchProductPriceController::class, 'activate']);
    Route::patch('branch-product-prices/{id}/deactivate', [BranchProductPriceController::class, 'deactivate']);
});
