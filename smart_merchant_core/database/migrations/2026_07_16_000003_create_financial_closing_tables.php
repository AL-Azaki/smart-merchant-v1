<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounting_periods', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('fiscal_year_id');
            $table->string('period_name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->string('status', 20)->default('Open');
            $table->foreignUuid('closed_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('closed_at')->nullable();
            $table->foreignUuid('reopened_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('reopened_at')->nullable();
            $table->text('reopen_reason')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamps();

            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'period_name']);
            // A simple unique index to help prevent identical periods
            $table->unique(['business_id', 'fiscal_year_id', 'start_date', 'end_date'], 'unq_accounting_period_dates');

            $table->foreign(['business_id', 'fiscal_year_id'])->references(['business_id', 'id'])->on('fiscal_years')->restrictOnDelete();
        });

        DB::statement("ALTER TABLE accounting_periods ADD CONSTRAINT chk_ap_lifecycle CHECK (status IN ('Open', 'Closing', 'Closed', 'Reopened'))");
        DB::statement("ALTER TABLE accounting_periods ADD CONSTRAINT chk_ap_dates CHECK (start_date <= end_date)");
        
        // Postgres extension for overlapping dates prevention (requires btree_gist)
        // Ignoring full gist exclusion to avoid extension dependency crashes, relying on application layer and simple uniqueness for overlaps.
    }

    public function down(): void
    {
        Schema::dropIfExists('accounting_periods');
    }
};
