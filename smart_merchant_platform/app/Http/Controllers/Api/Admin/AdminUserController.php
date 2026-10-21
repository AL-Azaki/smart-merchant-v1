<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->user()->load(['account', 'roles', 'branches']);
        
        return response()->json([
            'data' => [
                'id' => $user->id,
                'username' => $user->username,
                'email' => $user->email,
                'full_name' => $user->full_name,
                'account' => [
                    'id' => $user->account->id,
                    'name' => $user->account->name,
                    'owner_name' => $user->account->owner_name,
                ],
                'is_active' => $user->is_active,
                'roles' => $user->roles->map(function ($role) {
                    return [
                        'id' => $role->id,
                        'business_id' => $role->business_id,
                        'role_name' => $role->role_name,
                    ];
                }),
                'branches' => $user->branches->map(function ($branch) {
                    return [
                        'id' => $branch->id,
                        'business_id' => $branch->business_id,
                        'branch_name' => $branch->branch_name,
                    ];
                }),
            ]
        ]);
    }

    public function index(Request $request)
    {
        $query = \App\Models\User::with(['account', 'roles', 'branches']);

        // Scope to user's account if account_id exists
        if ($request->user()->account_id) {
            $query->where('account_id', $request->user()->account_id);
        }

        if ($request->filled('search')) {
            $search = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'like', $search)
                  ->orWhere('username', 'like', $search)
                  ->orWhere('email', 'like', $search);
            });
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', filter_var($request->query('is_active'), FILTER_VALIDATE_BOOLEAN));
        }

        $users = $query->latest()->paginate(20);

        return response()->json($users);
    }

    public function update(Request $request, string $id)
    {
        $query = \App\Models\User::query();
        if ($request->user()->account_id) {
            $query->where('account_id', $request->user()->account_id);
        }
        $user = $query->findOrFail($id);

        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'phone' => 'nullable|string|max:30',
            'is_active' => 'sometimes|boolean',
        ]);

        $user->update($validated);

        return response()->json([
            'data' => $user->fresh()->load(['account', 'roles', 'branches']),
            'message' => 'تم تحديث بيانات المستخدم بنجاح',
        ]);
    }
}
