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
        Schema::table('businesses', function (Blueprint $table) {
            $table->string('storefront_display_name', 150)->nullable()->after('storefront_slug');
            $table->boolean('storefront_active')->default(false)->after('storefront_display_name')->index();
            $table->string('storefront_whatsapp', 30)->nullable()->after('storefront_active');
            $table->string('storefront_phone', 30)->nullable()->after('storefront_whatsapp');
            $table->text('storefront_address_text')->nullable()->after('storefront_phone');
            $table->decimal('storefront_lat', 10, 7)->nullable()->after('storefront_address_text');
            $table->decimal('storefront_lng', 10, 7)->nullable()->after('storefront_lat');
            $table->json('storefront_theme_settings')->nullable()->after('storefront_lng');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('businesses', function (Blueprint $table) {
            $table->dropIndex(['storefront_active']);
            $table->dropColumn([
                'storefront_display_name',
                'storefront_active',
                'storefront_whatsapp',
                'storefront_phone',
                'storefront_address_text',
                'storefront_lat',
                'storefront_lng',
                'storefront_theme_settings',
            ]);
        });
    }
};
