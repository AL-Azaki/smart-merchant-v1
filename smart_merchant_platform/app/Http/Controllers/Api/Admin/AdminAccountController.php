<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\Branch;
use App\Models\Business;
use App\Models\Permission;
use App\Models\Plan;
use App\Models\Role;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminAccountController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            // User fields (matching Flutter register_view.dart)
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'username' => 'required|string|max:50|unique:users,username',
            'email' => 'required|string|email|max:255|unique:users,email',
            'phone' => 'nullable|string|max:30',
            'password' => 'required|string|min:6',

            // Business fields (matching Flutter business_setup_view.dart)
            'business_name' => 'required|string|max:255',
            'business_type' => 'required|string|max:100',
            'primary_phone' => 'nullable|string|max:30',
            'primary_email' => 'nullable|email|max:255',
            'country' => 'nullable|string|max:100',
            'city' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:255',
            'currency' => 'nullable|string|max:10',
        ]);

        return DB::transaction(function () use ($validated) {
            $fullName = trim($validated['first_name'] . ' ' . $validated['last_name']);

            // 1. Create Account (Immediately Active for Admin-provisioned accounts)
            $account = Account::create([
                'name' => $validated['business_name'] . ' Account',
                'owner_name' => $fullName,
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? $validated['primary_phone'] ?? null,
                'status' => 'Active',
            ]);

            // 2. Create Business
            $business = Business::create([
                'account_id' => $account->id,
                'business_name' => $validated['business_name'],
                'business_type' => $validated['business_type'],
                'primary_phone' => $validated['primary_phone'] ?? $validated['phone'] ?? null,
                'primary_email' => $validated['primary_email'] ?? $validated['email'] ?? null,
                'status' => 'Active',
            ]);

            // 3. Create Default Branch
            $branchAddress = $validated['address'] ?? ($validated['city'] ? $validated['city'] . ($validated['country'] ? ', ' . $validated['country'] : '') : null);
            $branch = Branch::create([
                'business_id' => $business->id,
                'branch_name' => 'الفرع الرئيسي',
                'branch_code' => 'MAIN',
                'address' => $branchAddress,
                'phone' => $validated['primary_phone'] ?? $validated['phone'] ?? null,
                'email' => $validated['primary_email'] ?? $validated['email'] ?? null,
                'is_default' => true,
                'is_active' => true,
            ]);

            // 4. Create User (Active)
            $user = User::create([
                'account_id' => $account->id,
                'full_name' => $fullName,
                'username' => $validated['username'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password_hash' => Hash::make($validated['password']),
                'is_active' => true,
            ]);

            // 5. Connect User to Branch and set default branch
            $user->branches()->attach($branch->id);
            $user->update(['default_branch_id' => $branch->id]);

            // 6. Create Admin Role & assign permissions
            $role = Role::firstOrCreate([
                'business_id' => $business->id,
                'role_name' => 'Admin',
            ], [
                'description' => 'مدير النظام (Business Administrator)',
                'is_system_role' => true,
                'is_active' => true,
            ]);

            $permissions = Permission::all();
            if ($permissions->isNotEmpty()) {
                $role->permissions()->syncWithoutDetaching($permissions->pluck('id'));
            }
            $user->roles()->syncWithoutDetaching([$role->id]);

            // 7. Create Active Trial Subscription if plans exist
            $plan = Plan::where('is_active', true)->first();
            if ($plan) {
                Subscription::create([
                    'account_id' => $account->id,
                    'plan_id' => $plan->id,
                    'start_date' => now(),
                    'end_date' => now()->addMonths(1),
                    'amount_paid' => 0.00,
                    'status' => 'Active',
                ]);
            }

            return response()->json([
                'message' => 'تم إنشاء حساب العميل والنشاط التجاري بنجاح',
                'data' => [
                    'account' => $account->fresh()->loadCount(['businesses', 'users']),
                    'business' => $business,
                    'branch' => $branch,
                    'user' => [
                        'id' => $user->id,
                        'full_name' => $user->full_name,
                        'username' => $user->username,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'is_active' => $user->is_active,
                    ],
                    'credentials' => [
                        'email' => $user->email,
                        'password' => $validated['password'],
                    ],
                ],
            ], 201);
        });
    }
    public function index(Request $request)
    {
        $query = Account::withCount(['businesses', 'users']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', $search)
                  ->orWhere('owner_name', 'like', $search)
                  ->orWhere('email', 'like', $search);
            });
        }

        $accounts = $query->latest()->paginate(20);

        return response()->json($accounts);
    }

    public function show(Request $request, string $id)
    {
        $account = Account::with(['businesses', 'users'])->findOrFail($id);

        return response()->json(['data' => $account]);
    }

    public function update(Request $request, string $id)
    {
        $account = Account::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:200',
            'owner_name' => 'sometimes|string|max:150',
            'phone' => 'nullable|string|max:30',
            'status' => ['sometimes', 'string', Rule::in(['Pending', 'Active', 'Suspended', 'Closed'])],
            'reason' => 'nullable|string|max:500',
        ]);

        $account->update(collect($validated)->only(['name', 'owner_name', 'phone', 'status'])->toArray());

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تم تحديث حالة الحساب بنجاح',
        ]);
    }

    public function approve(Request $request, string $id)
    {
        $account = Account::findOrFail($id);
        $account->update(['status' => 'Active']);

        // Create an Active 1-Year Subscription for the merchant upon approval
        if ($account->subscriptions()->where('status', 'Active')->doesntExist()) {
            $plan = Plan::where('is_active', true)->first();
            if ($plan) {
                Subscription::create([
                    'account_id' => $account->id,
                    'plan_id' => $plan->id,
                    'start_date' => now(),
                    'end_date' => now()->addYear(),
                    'amount_paid' => 0.00,
                    'status' => 'Active',
                ]);
            }
        }

        // Send luxury branded approval notification email to merchant
        try {
            if ($account->email && filter_var($account->email, FILTER_VALIDATE_EMAIL)) {
                \Illuminate\Support\Facades\Mail::to($account->email)->send(new \App\Mail\AccountApprovedMail($account));
            }
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning("Failed to send approval email to {$account->email}: " . $e->getMessage());
        }

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تم تفعيل الحساب وإرسال بريد التأكيد بنجاح',
        ]);
    }

    public function suspend(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        $account = Account::findOrFail($id);
        $account->update(['status' => 'Suspended']);

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تم تعليق الحساب بنجاح',
        ]);
    }

    public function reactivate(Request $request, string $id)
    {
        $account = Account::findOrFail($id);
        $account->update(['status' => 'Active']);

        return response()->json([
            'data' => $account->fresh()->loadCount(['businesses', 'users']),
            'message' => 'تمت إعادة تنشيط الحساب بنجاح',
        ]);
    }
}
