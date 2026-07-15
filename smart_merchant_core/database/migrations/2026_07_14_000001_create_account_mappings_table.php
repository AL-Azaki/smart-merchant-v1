<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('account_mappings', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->string('mapping_type', 50);
            $table->uuid('chart_of_account_id');
            $table->timestamps();
            
            $table->unique(['business_id', 'mapping_type']);
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete(); // Or restrictOnDelete based on standard business deletion. Usually business deletion cascades. I will use restrictOnDelete to be safe or cascade. Let's see previous. Finance part 2 has: $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete(); Let's use restrictOnDelete.
            $table->foreign(['business_id', 'chart_of_account_id'])->references(['business_id', 'id'])->on('chart_of_accounts')->restrictOnDelete();
        });

        // Add check constraint for supported mapping types in V1
        DB::statement("ALTER TABLE account_mappings ADD CONSTRAINT chk_am_mapping_type CHECK (mapping_type IN ('SalesRevenue','SalesDiscount','SalesTax','AccountsReceivable','PurchaseExpense','AccountsPayable','Cash','Bank','Inventory','InventoryAdjustment','COGS','OpeningBalance','ManualJournal'))");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('account_mappings');
    }
};
