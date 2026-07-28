<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class AdminBusinessUserController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $users = User::where('account_id', $business->account_id)
            ->with(['roles' => function($q) use ($business) {
                $q->where('business_id', $business->id);
            }, 'branches' => function($q) use ($business) {
                $q->where('business_id', $business->id);
            }])
            ->paginate(20);

        return response()->json($users);
    }

    public function store(Request $request, Business $business)
    {
        $validated = $request->validate([
            'username' => ['required', 'string', 'max:50', Rule::unique('users')->where('account_id', $business->account_id)],
            'email' => 'required|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'full_name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'role_ids' => 'array',
            'role_ids.*' => ['uuid', Rule::exists('roles', 'id')->where('business_id', $business->id)],
            'branch_ids' => 'array',
            'branch_ids.*' => ['uuid', Rule::exists('branches', 'id')->where('business_id', $business->id)],
        ]);

        $user = DB::transaction(function () use ($validated, $business) {
            $user = User::create([
                'account_id' => $business->account_id,
                'username' => $validated['username'],
                'email' => $validated['email'],
                'password_hash' => Hash::make($validated['password']),
                'full_name' => $validated['full_name'],
                'phone' => $validated['phone'] ?? null,
                'is_active' => true,
            ]);

            if (!empty($validated['role_ids'])) {
                $user->roles()->attach($validated['role_ids']);
            }

            if (!empty($validated['branch_ids'])) {
                $user->branches()->attach($validated['branch_ids']);
            }

            return $user;
        });

        return response()->json(['data' => $user->load('roles', 'branches')], 201);
    }

    public function show(Request $request, Business $business, User $user)
    {
        if ($user->account_id !== $business->account_id) {
            abort(404);
        }

        $user->load(['roles' => function($q) use ($business) {
            $q->where('business_id', $business->id);
        }, 'branches' => function($q) use ($business) {
            $q->where('business_id', $business->id);
        }]);

        return response()->json(['data' => $user]);
    }

    public function update(Request $request, Business $business, User $user)
    {
        if ($user->account_id !== $business->account_id) {
            abort(404);
        }

        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'phone' => 'nullable|string|max:30',
            'is_active' => 'boolean',
            'role_ids' => 'array',
            'role_ids.*' => ['uuid', Rule::exists('roles', 'id')->where('business_id', $business->id)],
            'branch_ids' => 'array',
            'branch_ids.*' => ['uuid', Rule::exists('branches', 'id')->where('business_id', $business->id)],
        ]);

        DB::transaction(function () use ($validated, $business, $user) {
            $updateData = collect($validated)->only(['full_name', 'phone', 'is_active'])->toArray();
            if (!empty($updateData)) {
                $user->update($updateData);
            }

            if (isset($validated['role_ids'])) {
                $existingRoles = $user->roles()->where('business_id', '!=', $business->id)->pluck('id')->toArray();
                $user->roles()->sync(array_merge($existingRoles, $validated['role_ids']));
            }

            if (isset($validated['branch_ids'])) {
                $existingBranches = $user->branches()->where('business_id', '!=', $business->id)->pluck('id')->toArray();
                $user->branches()->sync(array_merge($existingBranches, $validated['branch_ids']));
            }
        });

        return response()->json(['data' => $user->refresh()->load('roles', 'branches')]);
    }
}
