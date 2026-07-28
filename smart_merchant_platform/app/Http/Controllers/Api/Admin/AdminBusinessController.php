<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminBusinessController extends Controller
{
    public function index(Request $request)
    {
        $businesses = Business::where('account_id', $request->user()->account_id)
            ->paginate(20);

        return response()->json($businesses);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'business_name' => 'required|string|max:200',
            'business_type' => 'required|string|max:50',
            'primary_phone' => 'nullable|string|max:30',
            'primary_email' => 'nullable|email|max:255',
        ]);

        $business = Business::create([
            'account_id' => $request->user()->account_id,
            'business_name' => $validated['business_name'],
            'business_type' => $validated['business_type'],
            'primary_phone' => $validated['primary_phone'],
            'primary_email' => $validated['primary_email'],
            'status' => 'Active',
            'revision' => 1,
            'storefront_slug' => Str::slug($validated['business_name']) . '-' . Str::random(6),
        ]);

        return response()->json(['data' => $business], 201);
    }

    public function show(Request $request, string $id)
    {
        $business = Business::where('account_id', $request->user()->account_id)->findOrFail($id);
        
        return response()->json(['data' => $business]);
    }

    public function update(Request $request, string $id)
    {
        $business = Business::where('account_id', $request->user()->account_id)->findOrFail($id);

        $validated = $request->validate([
            'business_name' => 'sometimes|string|max:200',
            'business_type' => 'sometimes|string|max:50',
            'primary_phone' => 'nullable|string|max:30',
            'primary_email' => 'nullable|email|max:255',
            'status' => ['sometimes', 'string', Rule::in(['Active', 'Suspended', 'Closed'])],
            'storefront_slug' => ['sometimes', 'string', 'max:255', Rule::unique('businesses')->ignore($business->id)],
        ]);

        $business->update($validated);

        return response()->json(['data' => $business->refresh()]);
    }
}
