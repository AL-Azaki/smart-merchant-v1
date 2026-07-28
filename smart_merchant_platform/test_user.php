<?php
$user = App\Models\User::where('email', 'admin@smartmerchant.com')->first();
echo 'EXISTS: ' . ($user ? 'YES' : 'NO') . PHP_EOL;
if ($user) {
    echo 'EMAIL: ' . $user->email . PHP_EOL;
    echo 'PASSWORD_HASH: ' . $user->password_hash . PHP_EOL;
    echo 'HASH_CHECK: ' . (Hash::check('admin123', $user->password_hash) ? 'TRUE' : 'FALSE') . PHP_EOL;
}
