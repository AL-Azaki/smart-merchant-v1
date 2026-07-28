<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $tables = [
            'products', 'categories', 'brands', 'units', 'product_units', 'product_images',
            'orders', 'businesses', 'branches',
        ];

        foreach ($tables as $table) {
            Schema::table($table, function (Blueprint $t) {
                $t->integer('revision')->default(1);
            });
        }
    }

    public function down(): void
    {
        $tables = [
            'products', 'categories', 'brands', 'units', 'product_units', 'product_images',
            'orders', 'businesses', 'branches',
        ];

        foreach ($tables as $table) {
            Schema::table($table, function (Blueprint $t) {
                $t->dropColumn('revision');
            });
        }
    }
};
