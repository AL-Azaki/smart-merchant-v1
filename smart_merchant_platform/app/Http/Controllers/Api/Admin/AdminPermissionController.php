<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Permission;
use Illuminate\Http\Request;

class AdminPermissionController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $permissions = Permission::all();
        return response()->json(['data' => $permissions]);
    }
}
