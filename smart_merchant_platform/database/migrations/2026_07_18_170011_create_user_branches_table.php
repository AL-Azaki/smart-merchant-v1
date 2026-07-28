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
     * Table: user_branches (Pivot)
     * Purpose: Many-to-many pivot between users and branches they can access.
     */
    public function up(): void
    {
        Schema::create('user_branches', function (Blueprint $table) {
            $table->uuid('user_id');
            $table->uuid('branch_id');
            $table->boolean('is_active')->default(true);
            $table->timestamp('assigned_at')->default(DB::raw('CURRENT_TIMESTAMP'));

            $table->primary(['user_id', 'branch_id']);

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade')
                ->onUpdate('cascade');

            $table->foreign('branch_id')
                ->references('id')
                ->on('branches')
                ->onDelete('cascade')
                ->onUpdate('cascade');
        });

        // Add composite FK from users(id, default_branch_id) to user_branches(user_id, branch_id)
        DB::statement('ALTER TABLE users ADD CONSTRAINT fk_users_default_branch FOREIGN KEY (id, default_branch_id) REFERENCES user_branches(user_id, branch_id) ON DELETE RESTRICT ON UPDATE RESTRICT;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_default_branch;');
        Schema::dropIfExists('user_branches');
    }
};
