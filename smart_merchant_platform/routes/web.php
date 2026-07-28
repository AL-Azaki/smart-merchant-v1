<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group.
|
*/

Route::get('/', function () {
    return view('welcome');
});

/*
|--------------------------------------------------------------------------
| Authentication & Authorization Routes (Web)
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    // Web login, logout, and password management routes will be registered here.
});

/*
|--------------------------------------------------------------------------
| Admin Dashboard Routes
|--------------------------------------------------------------------------
| Platform management: Accounts, Businesses, Branches, and Subscriptions.
*/
Route::prefix('admin')->group(function () {
    // Admin dashboard routes will be registered here.
});

/*
|--------------------------------------------------------------------------
| E-Commerce Routes
|--------------------------------------------------------------------------
| Public storefront and customer ordering routes.
*/
Route::prefix('shop')->group(function () {
    // E-commerce storefront routes will be registered here.
});
