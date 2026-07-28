<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminSubscriptionController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $subscriptions = Subscription::where('account_id', $business->account_id)->with('plan')->paginate(20);
        return response()->json($subscriptions);
    }

    public function show(Request $request, Business $business, Subscription $subscription)
    {
        if ($subscription->account_id !== $business->account_id) {
            abort(404);
        }
        
        $subscription->load('plan');
        return response()->json(['data' => $subscription]);
    }

    public function update(Request $request, Business $business, Subscription $subscription)
    {
        if ($subscription->account_id !== $business->account_id) {
            abort(404);
        }

        $validated = $request->validate([
            'status' => ['sometimes', 'string', Rule::in(['Active', 'Suspended', 'Expired'])],
        ]);

        $subscription->update($validated);

        return response()->json(['data' => $subscription->refresh()]);
    }
}
