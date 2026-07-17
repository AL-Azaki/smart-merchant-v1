<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_receivables', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('customer_id');
            $table->uuid('branch_id')->nullable();
            $table->uuid('currency_id');
            
            $table->string('status', 30)->default('Open');
            $table->decimal('current_balance', 18, 4)->default(0.0000);
            $table->decimal('credit_limit', 18, 4)->default(0.0000);
            $table->date('due_date')->nullable();
            
            $table->uuid('responsible_user_id')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            
            $table->timestamps();
            
            // Indexes and Foreign Keys
            $table->unique(['business_id', 'id']);
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            // Assuming customers and branches use composite FKs or standard FKs, using standard fallback style
            $table->foreign(['business_id', 'customer_id'])->references(['business_id', 'id'])->on('customers')->restrictOnDelete();
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign('currency_id')->references('id')->on('currencies')->restrictOnDelete();
            
            $table->foreign('responsible_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
            $table->foreign('updated_by')->references('id')->on('users')->nullOnDelete();
        });
        
        DB::statement("ALTER TABLE customer_receivables ADD CONSTRAINT chk_cr_status CHECK (status IN ('Open', 'Partially Paid', 'Fully Paid', 'Overdue', 'Written Off'))");

        Schema::create('receivable_entries', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('customer_receivable_id');
            
            $table->string('entry_type', 50);
            $table->string('direction', 10);
            $table->decimal('amount', 18, 4);
            
            $table->decimal('foreign_currency_amount', 18, 4)->nullable();
            $table->string('foreign_currency_code', 3)->nullable();
            $table->decimal('exchange_rate', 18, 6)->nullable();
            
            // Polymorphic Document Policy
            $table->string('document_type')->nullable();
            $table->uuid('document_id')->nullable();
            
            $table->uuid('created_by')->nullable();
            
            $table->timestamps();
            
            // Indexes and Foreign Keys
            $table->unique(['business_id', 'id']);
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign(['business_id', 'customer_receivable_id'])->references(['business_id', 'id'])->on('customer_receivables')->cascadeOnDelete();
            
            $table->index(['document_type', 'document_id']);
            $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
        });
        
        DB::statement("ALTER TABLE receivable_entries ADD CONSTRAINT chk_re_type CHECK (entry_type IN ('Invoice', 'Payment', 'Credit Note', 'Debit Note', 'Adjustment', 'Write-off'))");
        DB::statement("ALTER TABLE receivable_entries ADD CONSTRAINT chk_re_direction CHECK (direction IN ('Debit', 'Credit'))");
        DB::statement("ALTER TABLE receivable_entries ADD CONSTRAINT chk_re_amount CHECK (amount > 0)");
    }

    public function down(): void
    {
        Schema::dropIfExists('receivable_entries');
        Schema::dropIfExists('customer_receivables');
    }
};
