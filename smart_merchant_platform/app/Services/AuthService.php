<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function login(string $loginIdentifier, string $password, ?string $deviceName): array
    {
        $cleanPhone = preg_replace('/[^0-9]/', '', $loginIdentifier);

        $user = User::where('email', $loginIdentifier)
            ->orWhere('username', $loginIdentifier)
            ->orWhere('phone', $loginIdentifier)
            ->when(!empty($cleanPhone), function ($q) use ($cleanPhone) {
                $q->orWhere('phone', 'like', "%{$cleanPhone}%");
            })
            ->first();

        if (! $user || ! Hash::check($password, $user->password_hash)) {
            throw ValidationException::withMessages([
                'email' => ['بيانات تسجيل الدخول غير صحيحة.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['حساب المستخدم معطل حالياً.'],
            ]);
        }

        $user->update(['last_login_at' => now()]);

        $tokenName = $deviceName ?? 'default-device';
        $token = $user->createToken($tokenName)->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    public function register(array $data, ?string $deviceName): array
    {
        return \Illuminate\Support\Facades\DB::transaction(function () use ($data, $deviceName) {
            $phone = trim($data['phone'] ?? '');
            $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
            if (empty($cleanPhone)) {
                $cleanPhone = (string) rand(10000000, 99999999);
            }

            // Extract names
            $fullName = trim(($data['name'] ?? '') ?: (($data['first_name'] ?? '') . ' ' . ($data['last_name'] ?? '')));
            if (empty($fullName)) {
                $fullName = 'التاجر ' . substr($cleanPhone, -4);
            }
            $firstName = $data['first_name'] ?? (explode(' ', $fullName)[0] ?? 'التاجر');
            $lastName = $data['last_name'] ?? (explode(' ', $fullName, 2)[1] ?? 'المعتمد');

            // Generate clean unique username if not provided
            $username = $data['username'] ?? null;
            if (!$username) {
                $baseUser = 'u_' . substr($cleanPhone, -8);
                $username = $baseUser;
                $counter = 1;
                while (User::where('username', $username)->exists()) {
                    $username = $baseUser . '_' . $counter++;
                }
            }

            // Generate clean unique fallback email if not provided
            $email = $data['email'] ?? null;
            if (!$email) {
                $baseEmail = 'u' . $cleanPhone . '@smartmerchant.local';
                $email = $baseEmail;
                $counter = 1;
                while (User::where('email', $email)->exists()) {
                    $email = 'u' . $cleanPhone . '_' . $counter++ . '@smartmerchant.local';
                }
            }

            $businessName = trim($data['business_name'] ?? '') ?: ($fullName . ' - المتجر');

            // 1. Create Account
            $account = \App\Models\Account::create([
                'name' => $businessName . ' Account',
                'owner_name' => $fullName,
                'email' => $email,
                'phone' => $phone,
                'status' => 'Active',
            ]);

            // 2. Create Business
            $business = \App\Models\Business::create([
                'account_id' => $account->id,
                'business_name' => $businessName,
                'status' => 'Active',
            ]);

            // 3. Create Default Branch
            $branch = \App\Models\Branch::create([
                'business_id' => $business->id,
                'branch_name' => 'الفرع الرئيسي',
                'branch_code' => 'MAIN-01',
                'is_active' => true,
            ]);

            // 4. Create User
            $user = User::create([
                'account_id' => $account->id,
                'full_name' => $fullName,
                'username' => $username,
                'email' => $email,
                'phone' => $phone,
                'password_hash' => Hash::make($data['password']),
                'is_active' => true,
            ]);

            $user->branches()->attach($branch->id);
            $user->update(['default_branch_id' => $branch->id]);

            $tokenName = $deviceName ?? 'default-device';
            $token = $user->createToken($tokenName)->plainTextToken;

            return [
                'user' => $user,
                'token' => $token,
            ];
        });
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()->delete();
    }
}
