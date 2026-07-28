<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Role;
use Illuminate\Http\Request;

class AdminRoleController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $roles = $business->roles()->with('permissions')->paginate(20);
        return response()->json($roles);
    }

    public function show(Request $request, Business $business, Role $role)
    {
        if ($role->business_id !== $business->id) {
            abort(404);
        }
        
        $role->load('permissions');
        return response()->json(['data' => $role]);
    }
}
