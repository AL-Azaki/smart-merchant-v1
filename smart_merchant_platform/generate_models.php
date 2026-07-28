<?php

$modelsDir = __DIR__.'/app/Models';
if (! is_dir($modelsDir)) {
    mkdir($modelsDir, 0777, true);
}

$models = [
    'Account' => [
        'fillable' => "['status']",
        'relations' => '
    public function businesses() { return $this->hasMany(Business::class); }
    public function users() { return $this->hasMany(User::class); }',
    ],
    'Currency' => [
        'fillable' => "['code', 'name', 'symbol', 'exchange_rate', 'is_default', 'is_active']",
        'relations' => '',
    ],
    'Permission' => [
        'fillable' => "['name', 'description']",
        'relations' => "
    public function roles() { return \$this->belongsToMany(Role::class, 'role_permissions'); }",
    ],
    'Business' => [
        'fillable' => "['account_id', 'business_name', 'business_type', 'primary_phone', 'primary_email', 'logo_path', 'status', 'revision']",
        'relations' => "
    public function account() { return \$this->belongsTo(Account::class); }
    public function branches() { return \$this->hasMany(Branch::class); }
    public function users() { return \$this->belongsToMany(User::class, 'user_branches'); }
    public function products() { return \$this->hasMany(Product::class); }
    public function orders() { return \$this->hasMany(Order::class); }
    public function devices() { return \$this->hasMany(Device::class); }",
    ],
    'Plan' => [
        'fillable' => "['plan_name', 'description', 'price_monthly', 'price_yearly', 'currency_id', 'features_json', 'is_active']",
        'relations' => '
    public function currency() { return $this->belongsTo(Currency::class); }',
    ],
    'Branch' => [
        'fillable' => "['business_id', 'branch_name', 'branch_code', 'address', 'phone', 'email', 'is_active', 'revision']",
        'relations' => "
    public function business() { return \$this->belongsTo(Business::class); }
    public function users() { return \$this->belongsToMany(User::class, 'user_branches'); }",
    ],
    'Role' => [
        'fillable' => "['business_id', 'name', 'description', 'is_system']",
        'relations' => "
    public function business() { return \$this->belongsTo(Business::class); }
    public function permissions() { return \$this->belongsToMany(Permission::class, 'role_permissions'); }
    public function users() { return \$this->belongsToMany(User::class, 'user_roles'); }",
    ],
    'Subscription' => [
        'fillable' => "['business_id', 'plan_id', 'status', 'starts_at', 'ends_at', 'trial_ends_at', 'canceled_at']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }
    public function plan() { return $this->belongsTo(Plan::class); }
    public function payments() { return $this->hasMany(SubscriptionPayment::class); }',
    ],
    'SubscriptionPayment' => [
        'fillable' => "['subscription_id', 'amount', 'currency_id', 'payment_date', 'payment_method', 'transaction_id', 'status']",
        'relations' => '
    public function subscription() { return $this->belongsTo(Subscription::class); }
    public function currency() { return $this->belongsTo(Currency::class); }',
    ],
    'Category' => [
        'fillable' => "['business_id', 'parent_id', 'name', 'slug', 'description', 'is_active', 'revision']",
        'relations' => "
    public function business() { return \$this->belongsTo(Business::class); }
    public function parent() { return \$this->belongsTo(Category::class, 'parent_id'); }
    public function children() { return \$this->hasMany(Category::class, 'parent_id'); }
    public function products() { return \$this->hasMany(Product::class); }",
    ],
    'Brand' => [
        'fillable' => "['business_id', 'name', 'slug', 'description', 'logo_path', 'is_active', 'revision']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }
    public function products() { return $this->hasMany(Product::class); }',
    ],
    'Unit' => [
        'fillable' => "['business_id', 'name', 'short_name', 'allow_decimal', 'is_active', 'revision']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }',
    ],
    'Product' => [
        'fillable' => "['business_id', 'category_id', 'brand_id', 'tax_id', 'product_type', 'product_code', 'product_name', 'description', 'is_active', 'revision']",
        'relations' => "
    public function business() { return \$this->belongsTo(Business::class); }
    public function category() { return \$this->belongsTo(Category::class); }
    public function brand() { return \$this->belongsTo(Brand::class); }
    public function units() { return \$this->hasMany(ProductUnit::class); }
    public function images() { return \$this->hasMany(ProductImage::class); }
    public function channels() { return \$this->belongsToMany(Channel::class, 'product_channels'); }",
    ],
    'ProductUnit' => [
        'fillable' => "['business_id', 'product_id', 'unit_id', 'is_base_unit', 'conversion_factor', 'barcode', 'price', 'revision']",
        'relations' => '
    public function product() { return $this->belongsTo(Product::class); }
    public function unit() { return $this->belongsTo(Unit::class); }',
    ],
    'ProductImage' => [
        'fillable' => "['business_id', 'product_id', 'image_path', 'is_primary', 'sort_order', 'revision']",
        'relations' => '
    public function product() { return $this->belongsTo(Product::class); }',
    ],
    'Channel' => [
        'fillable' => "['business_id', 'name', 'slug', 'channel_type', 'is_active']",
        'relations' => "
    public function business() { return \$this->belongsTo(Business::class); }
    public function products() { return \$this->belongsToMany(Product::class, 'product_channels'); }",
    ],
    'Cart' => [
        'fillable' => "['business_id', 'channel_id', 'customer_id', 'session_id', 'status', 'expires_at']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }
    public function channel() { return $this->belongsTo(Channel::class); }
    public function items() { return $this->hasMany(CartItem::class); }',
    ],
    'CartItem' => [
        'fillable' => "['cart_id', 'product_id', 'product_unit_id', 'quantity', 'unit_price', 'total_price']",
        'relations' => '
    public function cart() { return $this->belongsTo(Cart::class); }
    public function product() { return $this->belongsTo(Product::class); }
    public function productUnit() { return $this->belongsTo(ProductUnit::class); }',
    ],
    'Order' => [
        'fillable' => "['business_id', 'branch_id', 'channel_id', 'customer_id', 'order_number', 'order_date', 'currency_id', 'exchange_rate', 'sub_total', 'discount_total', 'tax_total', 'grand_total', 'base_sub_total', 'base_discount_total', 'base_tax_total', 'base_grand_total', 'payment_status', 'status', 'notes', 'created_by', 'revision']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }
    public function branch() { return $this->belongsTo(Branch::class); }
    public function channel() { return $this->belongsTo(Channel::class); }
    public function currency() { return $this->belongsTo(Currency::class); }
    public function items() { return $this->hasMany(OrderItem::class); }',
    ],
    'OrderItem' => [
        'fillable' => "['order_id', 'product_id', 'product_unit_id', 'quantity', 'unit_price', 'discount_amount', 'tax_amount', 'total_price', 'notes']",
        'relations' => '
    public function order() { return $this->belongsTo(Order::class); }
    public function product() { return $this->belongsTo(Product::class); }
    public function productUnit() { return $this->belongsTo(ProductUnit::class); }',
    ],
    'Device' => [
        'fillable' => "['business_id', 'user_id', 'device_uuid', 'device_name', 'platform', 'app_version', 'last_synced_at', 'revoked_at']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }
    public function user() { return $this->belongsTo(User::class); }',
    ],
    'IdempotencyKey' => [
        'fillable' => "['business_id', 'idempotency_key', 'operation', 'expires_at']",
        'relations' => '
    public function business() { return $this->belongsTo(Business::class); }',
    ],
];

foreach ($models as $name => $data) {
    $hasSoftDeletes = in_array($name, ['Account', 'Business', 'Branch', 'Product', 'Order', 'User', 'Device', 'Category', 'Brand', 'Unit', 'ProductUnit']);
    $softDeletesImport = $hasSoftDeletes ? "use Illuminate\Database\Eloquent\SoftDeletes;\n" : '';
    $softDeletesTrait = $hasSoftDeletes ? ', SoftDeletes' : '';

    $hasBusinessScope = strpos($data['fillable'], 'business_id') !== false;
    $scopeMethod = $hasBusinessScope ? "
    public function scopeForBusiness(\$query, \$businessId)
    {
        return \$query->where('business_id', \$businessId);
    }" : '';

    $content = <<<PHP
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
{$softDeletesImport}
class {$name} extends Model
{
    use HasFactory, HasUuids{$softDeletesTrait};

    protected \$fillable = {$data['fillable']};
{$data['relations']}
{$scopeMethod}
}
PHP;

    file_put_contents($modelsDir.'/'.$name.'.php', $content);
}

// Update User model
$userContent = <<<PHP
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasUuids, SoftDeletes;

    protected \$fillable = [
        'account_id',
        'default_branch_id',
        'username',
        'email',
        'password_hash',
        'full_name',
        'phone',
        'is_active',
        'last_login_at',
    ];

    protected \$hidden = [
        'password_hash',
    ];

    public function getAuthPassword()
    {
        return \$this->password_hash;
    }

    public function account() { return \$this->belongsTo(Account::class); }
    public function defaultBranch() { return \$this->belongsTo(Branch::class, 'default_branch_id'); }
    public function branches() { return \$this->belongsToMany(Branch::class, 'user_branches'); }
    public function roles() { return \$this->belongsToMany(Role::class, 'user_roles'); }
    public function devices() { return \$this->hasMany(Device::class); }
}
PHP;
file_put_contents($modelsDir.'/User.php', $userContent);

echo "Models generated.\n";
