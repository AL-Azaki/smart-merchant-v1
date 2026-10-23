<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Models\Subscription;
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
            'city' => 'nullable|string|max:100',
            'address' => 'nullable|string|max:255',
            'installment_plan' => 'nullable|string|max:50',
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

        $addressText = trim(($request->input('city') ? $request->input('city') . ' - ' : '') . ($request->input('address') ?? ''));

        // Update the business with the actual details
        $business->update([
            'business_name' => $request->input('business_name'),
            'business_type' => $request->input('business_type'),
            'primary_phone' => $request->input('primary_phone'),
            'primary_email' => $request->input('primary_email'),
            'storefront_address_text' => $addressText ?: $business->storefront_address_text,
            'status' => 'Active',
        ]);

        // Only attach an active subscription if the account is already Active (not Pending approval)
        $account = $business->account;
        if ($account && $account->status === 'Active' && $account->subscriptions()->where('status', 'Active')->doesntExist()) {
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

        return response()->json([
            'message' => 'Business setup completed successfully',
            'business' => $business->fresh(),
        ]);
    }
}
