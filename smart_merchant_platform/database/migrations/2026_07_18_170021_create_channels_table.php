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
     * Table: channels
     * Purpose: Sales channel definitions (POS, Ecommerce, B2B, etc.).
     */
    public function up(): void
    {
        Schema::create('channels', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->string('channel_name', 100);
            $table->string('channel_code', 50);
            $table->string('channel_type', 50);
            $table->boolean('is_active')->default(true);

            $table->foreign('business_id')
                ->references('id')
                ->on('businesses')
                ->onDelete('cascade')
                ->onUpdate('cascade');

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'channel_code']);
        });

        // Check constraint
        DB::statement("ALTER TABLE channels ADD CONSTRAINT chk_chan_type CHECK (channel_type IN ('POS', 'Ecommerce', 'B2B', 'Marketplace', 'Other'));");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('channels');
    }
};
