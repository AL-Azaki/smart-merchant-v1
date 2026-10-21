<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('customer_name', 150)->nullable()->after('customer_id');
            $table->string('customer_phone', 30)->nullable()->after('customer_name');
            $table->string('customer_email', 255)->nullable()->after('customer_phone');
            $table->text('shipping_address')->nullable()->after('customer_email');
            $table->string('shipping_city', 100)->nullable()->after('shipping_address');
            $table->text('customer_notes')->nullable()->after('shipping_city');
            $table->string('source', 50)->default('storefront')->after('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'customer_name',
                'customer_phone',
                'customer_email',
                'shipping_address',
                'shipping_city',
                'customer_notes',
                'source',
            ]);
        });
    }
};
