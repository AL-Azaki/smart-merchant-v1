<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Branch;
use Illuminate\Http\Request;

class AdminBranchController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $branches = $business->branches()->paginate(20);
        return response()->json($branches);
    }

    public function store(Request $request, Business $business)
    {
        $validated = $request->validate([
            'branch_name' => 'required|string|max:200',
            'branch_code' => 'required|string|max:50',
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:30',
            'is_online_branch' => 'boolean',
        ]);

        $branch = $business->branches()->create(array_merge($validated, [
            'is_active' => true,
        ]));

        return response()->json(['data' => $branch], 201);
    }

    public function show(Request $request, Business $business, Branch $branch)
    {
        if ($branch->business_id !== $business->id) {
            abort(404);
        }
        return response()->json(['data' => $branch]);
    }

    public function update(Request $request, Business $business, Branch $branch)
    {
        if ($branch->business_id !== $business->id) {
            abort(404);
        }

        $validated = $request->validate([
            'branch_name' => 'sometimes|string|max:200',
            'branch_code' => 'sometimes|string|max:50',
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:30',
            'is_active' => 'boolean',
            'is_online_branch' => 'boolean',
        ]);

        $branch->update($validated);

        return response()->json(['data' => $branch->refresh()]);
    }
}
