<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BusinessSetupController extends Controller
{
    public function completeSetup(Request $request): JsonResponse
    {
        $request->validate([
            'business_type' => 'required|string|max:100',
            'business_name' => 'required|string|max:255',
            'primary_phone' => 'nullable|string|max:30',
            'primary_email' => 'nullable|email|max:255',
            // Assume other fields can be added here
        ]);

        $user = $request->user();
        
        // Ensure user has a default branch / business
        $branch = $user->defaultBranch;
        if (!$branch) {
            return response()->json(['message' => 'No business branch found for user'], 400);
        }

        $business = $branch->business;
        if (!$business) {
            return response()->json(['message' => 'No business found'], 400);
        }

        // Update the business with the actual details
        $business->update([
            'business_name' => $request->input('business_name'),
            'business_type' => $request->input('business_type'),
            'primary_phone' => $request->input('primary_phone'),
            'primary_email' => $request->input('primary_email'),
        ]);

        return response()->json([
            'message' => 'Business setup completed successfully',
            'business' => $business,
        ]);
    }
}
