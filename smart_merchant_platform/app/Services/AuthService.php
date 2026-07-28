<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function login(string $email, string $password, ?string $deviceName): array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password_hash)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials provided.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['User account is inactive.'],
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
            // For a full ERP, registration usually creates an Account/Tenant first.
            $account = \App\Models\Account::create([
                'name' => $data['first_name'] . ' Account',
                'owner_name' => $data['first_name'] . ' ' . $data['last_name'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'status' => 'Active',
            ]);

            $business = \App\Models\Business::create([
                'account_id' => $account->id,
                'business_name' => $data['first_name'] . ' Business',
                'status' => 'Active',
            ]);

            $branch = \App\Models\Branch::create([
                'business_id' => $business->id,
                'branch_name' => 'Main Branch',
                'branch_code' => 'MAIN',
                'is_active' => true,
            ]);

            $user = User::create([
                'account_id' => $account->id,
                'full_name' => $data['first_name'] . ' ' . $data['last_name'],
                'username' => $data['username'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
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
