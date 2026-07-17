<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // ==========================================
        // DOMAIN 3 - CATALOG
        // ==========================================
        Schema::create('categories', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('parent_id')->nullable();
            $table->string('category_name', 100);
            $table->string('category_code', 50)->nullable();
            $table->text('description')->nullable();
            $table->string('image_path', 500)->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'category_name']);
            $table->unique(['business_id', 'category_code']);
            // Composite FK for parent
            $table->foreign(['business_id', 'parent_id'])->references(['business_id', 'id'])->on('categories')->restrictOnDelete();
        });

        Schema::create('brands', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('brand_name', 100);
            $table->text('description')->nullable();
            $table->string('logo_path', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'brand_name']);
        });

        Schema::create('units', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->string('unit_name', 100);
            $table->string('unit_symbol', 10);
            $table->text('unit_description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'unit_name']);
            $table->unique(['business_id', 'unit_symbol']);
        });

        Schema::create('products', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('category_id')->nullable();
            $table->uuid('brand_id')->nullable();
            $table->uuid('tax_id')->nullable();
            $table->string('product_type', 50)->default('standard');
            $table->string('product_code', 100);
            $table->string('product_name', 255);
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'product_code']);
            $table->foreign(['business_id', 'category_id'])->references(['business_id', 'id'])->on('categories')->restrictOnDelete();
            $table->foreign(['business_id', 'brand_id'])->references(['business_id', 'id'])->on('brands')->restrictOnDelete();
        });

        Schema::create('product_units', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('product_id');
            $table->foreignUuid('unit_id')->constrained('units')->restrictOnDelete();
            $table->string('sku', 100)->nullable();
            $table->string('barcode', 100)->nullable();
            $table->decimal('conversion_factor', 18, 4)->default(1.0000);
            $table->decimal('purchase_price', 18, 2)->default(0.00);
            $table->decimal('selling_price', 18, 2)->default(0.00);
            $table->decimal('minimum_price', 18, 2)->default(0.00);
            $table->boolean('is_base_unit')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'barcode']);
            $table->unique(['business_id', 'sku']);
            $table->unique(['product_id', 'unit_id']);
            $table->foreign(['business_id', 'product_id'])->references(['business_id', 'id'])->on('products')->cascadeOnDelete();
        });
        DB::statement('ALTER TABLE product_units ADD CONSTRAINT chk_pu_conversion CHECK (conversion_factor > 0)');
        DB::statement('ALTER TABLE product_units ADD CONSTRAINT chk_pu_prices CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)');
        DB::statement('CREATE UNIQUE INDEX uq_product_units_one_base ON product_units (product_id) WHERE is_base_unit = TRUE');

        Schema::create('branch_product_prices', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('branch_id');
            $table->uuid('product_unit_id');
            $table->decimal('purchase_price', 18, 2)->default(0.00);
            $table->decimal('selling_price', 18, 2)->default(0.00);
            $table->decimal('minimum_price', 18, 2)->default(0.00);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['branch_id', 'product_unit_id']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->cascadeOnDelete();
        });
        DB::statement('ALTER TABLE branch_product_prices ADD CONSTRAINT chk_bpp_prices CHECK (purchase_price >= 0 AND selling_price >= minimum_price AND minimum_price >= 0)');

        Schema::create('product_images', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('image_path', 500);
            $table->boolean('is_primary')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });
        DB::statement('CREATE UNIQUE INDEX uq_product_images_primary ON product_images (product_id) WHERE is_primary = TRUE');

        // ==========================================
        // DOMAIN 4 - INVENTORY
        // ==========================================
        Schema::create('warehouses', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('branch_id');
            $table->string('warehouse_name', 255);
            $table->string('warehouse_code', 100);
            $table->string('address', 255)->nullable();
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'warehouse_code']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
        });
        DB::statement('CREATE UNIQUE INDEX uq_warehouses_default_branch ON warehouses (business_id, branch_id) WHERE is_default = TRUE');

        Schema::create('inventories', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->foreignUuid('warehouse_id')->constrained('warehouses')->restrictOnDelete();
            $table->foreignUuid('product_unit_id')->constrained('product_units')->restrictOnDelete();
            $table->decimal('quantity', 18, 3)->default(0.000);
            $table->decimal('average_cost', 18, 2)->default(0.00);
            $table->decimal('alert_quantity', 18, 3)->default(0.000);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['business_id', 'warehouse_id', 'product_unit_id']);
        });
        DB::statement('ALTER TABLE inventories ADD CONSTRAINT chk_inventories_values CHECK (quantity >= 0 AND average_cost >= 0 AND alert_quantity >= 0)');

        Schema::create('inventory_transactions', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('branch_id');
            $table->uuid('warehouse_id');
            $table->string('transaction_type', 20);
            $table->string('movement_direction', 3);
            $table->string('status', 20)->default('Draft');
            $table->string('reference_type', 50)->nullable();
            $table->uuid('reference_id')->nullable();
            $table->timestamp('transaction_date')->useCurrent();
            
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->uuid('posted_by')->nullable();
            $table->timestamp('posted_at')->nullable();
            $table->uuid('reversed_by')->nullable();
            $table->timestamp('reversed_at')->nullable();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->foreign(['business_id', 'branch_id'])->references(['business_id', 'id'])->on('branches')->restrictOnDelete();
            $table->foreign(['business_id', 'warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
            $table->foreign('posted_by')->references('id')->on('users')->restrictOnDelete();
            $table->foreign('reversed_by')->references('id')->on('users')->restrictOnDelete();
        });
        
        DB::statement("ALTER TABLE inventory_transactions ADD CONSTRAINT chk_inv_tx_status CHECK (status IN ('Draft','Posted','Reversed'))");
        DB::statement("ALTER TABLE inventory_transactions ADD CONSTRAINT chk_inv_tx_type CHECK (transaction_type IN ('Receipt','Dispatch','Adjustment In','Adjustment Out','Opening Balance'))");
        DB::statement("ALTER TABLE inventory_transactions ADD CONSTRAINT chk_inv_tx_movement CHECK (movement_direction IN ('IN','OUT'))");
        DB::statement("ALTER TABLE inventory_transactions ADD CONSTRAINT chk_inv_tx_ref CHECK (reference_type IN ('SalesInvoice','SalesReturn','PurchaseInvoice','PurchaseReturn','Transfer','Adjustment') OR reference_type IS NULL)");
        DB::statement('CREATE INDEX idx_inv_tx_reference ON inventory_transactions (reference_type, reference_id)');

        Schema::create('inventory_transaction_lines', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('inventory_transaction_id');
            $table->uuid('product_unit_id');
            $table->integer('line_number')->default(1);
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_cost', 18, 2)->default(0.00);
            
            $table->foreign(['business_id', 'inventory_transaction_id'], 'fk_inv_tx_lines_tx')->references(['business_id', 'id'])->on('inventory_transactions')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'], 'fk_inv_tx_lines_prod')->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
        });
        
        DB::statement('ALTER TABLE inventory_transaction_lines ADD CONSTRAINT chk_inv_tx_line_qty CHECK (quantity > 0)');
        DB::statement('ALTER TABLE inventory_transaction_lines ADD CONSTRAINT chk_inv_tx_line_cost CHECK (unit_cost >= 0)');

        Schema::create('inventory_transfers', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->foreignUuid('business_id')->constrained('businesses')->restrictOnDelete();
            $table->uuid('from_warehouse_id');
            $table->uuid('to_warehouse_id');
            $table->string('transfer_number', 50);
            $table->timestamp('transfer_date')->useCurrent();
            $table->string('status', 20)->default('Pending');
            $table->text('notes')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            
            $table->unique(['business_id', 'id']);
            $table->unique(['business_id', 'transfer_number']);
            $table->foreign(['business_id', 'from_warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
            $table->foreign(['business_id', 'to_warehouse_id'])->references(['business_id', 'id'])->on('warehouses')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE inventory_transfers ADD CONSTRAINT chk_inv_transfers_status CHECK (status IN ('Pending','Completed','Cancelled'))");
        DB::statement("ALTER TABLE inventory_transfers ADD CONSTRAINT chk_inv_transfers_wh CHECK (from_warehouse_id <> to_warehouse_id)");

        Schema::create('inventory_transfer_items', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('business_id');
            $table->uuid('transfer_id');
            $table->uuid('product_unit_id');
            $table->decimal('quantity', 18, 3);
            $table->decimal('unit_cost', 18, 2)->default(0.00);
            
            $table->unique(['transfer_id', 'product_unit_id']);
            $table->foreign(['business_id', 'transfer_id'])->references(['business_id', 'id'])->on('inventory_transfers')->cascadeOnDelete();
            $table->foreign(['business_id', 'product_unit_id'])->references(['business_id', 'id'])->on('product_units')->restrictOnDelete();
        });
        DB::statement("ALTER TABLE inventory_transfer_items ADD CONSTRAINT chk_inv_ti_values CHECK (quantity > 0 AND unit_cost >= 0)");
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_transfer_items');
        Schema::dropIfExists('inventory_transfers');
        Schema::dropIfExists('inventory_transaction_lines');
        Schema::dropIfExists('inventory_transactions');
        Schema::dropIfExists('inventories');
        Schema::dropIfExists('warehouses');
        
        Schema::dropIfExists('product_images');
        Schema::dropIfExists('branch_product_prices');
        Schema::dropIfExists('product_units');
        Schema::dropIfExists('products');
        Schema::dropIfExists('units');
        Schema::dropIfExists('brands');
        Schema::dropIfExists('categories');
    }
};
