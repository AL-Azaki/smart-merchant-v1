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
}
