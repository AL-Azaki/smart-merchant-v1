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
     * Table: product_channels (Pivot)
     * Purpose: Many-to-many pivot associating product units with sales channels, including custom pricing and availability.
     */
    public function up(): void
    {
        Schema::create('product_channels', function (Blueprint $table) {
            $table->uuid('business_id');
            $table->uuid('product_unit_id');
            $table->uuid('channel_id');
            $table->decimal('price', 18, 2)->default(0.00);
            $table->boolean('is_available')->default(true);
            $table->timestamps();

            $table->primary(['product_unit_id', 'channel_id']);
        });

        // Composite foreign keys to product_units and channels
        DB::statement('ALTER TABLE product_channels ADD CONSTRAINT fk_pc_product_unit FOREIGN KEY (business_id, product_unit_id) REFERENCES product_units(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');
        DB::statement('ALTER TABLE product_channels ADD CONSTRAINT fk_pc_channel FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE CASCADE ON UPDATE CASCADE;');

        // Check constraint
        DB::statement('ALTER TABLE product_channels ADD CONSTRAINT chk_pc_price CHECK (price >= 0);');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE product_channels DROP CONSTRAINT IF EXISTS fk_pc_channel;');
        DB::statement('ALTER TABLE product_channels DROP CONSTRAINT IF EXISTS fk_pc_product_unit;');
        Schema::dropIfExists('product_channels');
    }
};
