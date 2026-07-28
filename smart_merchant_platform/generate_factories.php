<?php

$factoriesDir = __DIR__.'/database/factories';
if (! is_dir($factoriesDir)) {
    mkdir($factoriesDir, 0777, true);
}

$factories = [
    'AccountFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Account;
use Illuminate\Database\Eloquent\Factories\Factory;

class AccountFactory extends Factory
{
    protected \$model = Account::class;
    public function definition()
    {
        return [
            'status' => 'Active',
        ];
    }
}
PHP,
    'BusinessFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Business;
use App\Models\Account;
use Illuminate\Database\Eloquent\Factories\Factory;

class BusinessFactory extends Factory
{
    protected \$model = Business::class;
    public function definition()
    {
        return [
            'account_id' => Account::factory(),
            'business_name' => \$this->faker->company(),
            'business_type' => 'Retail',
            'status' => 'Active',
            'revision' => 1,
        ];
    }
}
PHP,
    'UserFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\User;
use App\Models\Account;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected \$model = User::class;
    protected static ?string \$password;
    public function definition()
    {
        return [
            'account_id' => Account::factory(),
            'username' => \$this->faker->unique()->userName(),
            'email' => \$this->faker->unique()->safeEmail(),
            'password_hash' => static::\$password ??= Hash::make('password'),
            'full_name' => \$this->faker->name(),
            'is_active' => true,
        ];
    }
}
PHP,
    'DeviceFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Device;
use App\Models\Business;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class DeviceFactory extends Factory
{
    protected \$model = Device::class;
    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'device_uuid' => Str::uuid()->toString(),
            'device_name' => 'Test Device',
        ];
    }
}
PHP,
    'ProductFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Product;
use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class ProductFactory extends Factory
{
    protected \$model = Product::class;
    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'product_code' => Str::random(10),
            'product_name' => \$this->faker->word(),
            'is_active' => true,
            'revision' => 1,
        ];
    }
}
PHP,
    'OrderFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Order;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Channel;
use App\Models\Currency;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class OrderFactory extends Factory
{
    protected \$model = Order::class;
    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'branch_id' => Branch::factory(),
            'channel_id' => Channel::factory(),
            'currency_id' => Currency::factory(),
            'order_number' => 'ORD-' . strtoupper(Str::random(6)),
            'revision' => 1,
        ];
    }
}
PHP,
    'BranchFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Branch;
use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class BranchFactory extends Factory
{
    protected \$model = Branch::class;
    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'branch_name' => \$this->faker->company(),
            'branch_code' => Str::random(5),
            'is_active' => true,
            'revision' => 1,
        ];
    }
}
PHP,
    'ChannelFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Channel;
use App\Models\Business;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class ChannelFactory extends Factory
{
    protected \$model = Channel::class;
    public function definition()
    {
        return [
            'business_id' => Business::factory(),
            'name' => 'Storefront',
            'slug' => 'storefront-' . Str::random(5),
            'is_active' => true,
        ];
    }
}
PHP,
    'CurrencyFactory' => <<<PHP
<?php
namespace Database\Factories;
use App\Models\Currency;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class CurrencyFactory extends Factory
{
    protected \$model = Currency::class;
    public function definition()
    {
        return [
            'code' => strtoupper(Str::random(3)),
            'name' => \$this->faker->currencyCode(),
            'is_active' => true,
        ];
    }
}
PHP
];

foreach ($factories as $name => $content) {
    file_put_contents($factoriesDir.'/'.$name.'.php', $content);
}

echo "Factories generated.\n";
