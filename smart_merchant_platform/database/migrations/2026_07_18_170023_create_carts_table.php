<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Table: carts
     * Purpose: Shopping carts for channels/customers, supporting online orders and draft POS transactions.
     */
    public function up(): void
    {
        Schema::create('carts', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('channel_id');
            $table->uuid('customer_id')->nullable(); // No FK constraint in PostgreSQL migration (Customer owned by SQLite ERP)
            $table->string('session_id', 255)->nullable();
            $table->uuid('currency_id');
            $table->decimal('exchange_rate', 18, 8)->default(1.00000000);
            $table->decimal('sub_total', 18, 2)->default(0.00);
            $table->decimal('discount_total', 18, 2)->default(0.00);
            $table->decimal('tax_total', 18, 2)->default(0.00);
            $table->decimal('grand_total', 18, 2)->default(0.00);
            $table->string('status', 20)->default('Active');
            $table->timestamps();

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->foreign('currency_id')
                ->references('id')
                ->on('currencies')
                ->onDelete('restrict')
                ->onUpdate('restrict');

            $table->unique(['business_id', 'id']);
        });

        // Composite foreign key to channels
        DB::statement('ALTER TABLE carts ADD CONSTRAINT fk_carts_channel FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');

        // Check constraint
        DB::statement("ALTER TABLE carts ADD CONSTRAINT chk_cart_status CHECK (status IN ('Active', 'Converted', 'Abandoned'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE carts DROP CONSTRAINT IF EXISTS fk_carts_channel;');
        Schema::dropIfExists('carts');
    }
};
