<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\User;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    public function index(Request $request)
    {
        $accountId = $request->user()->account_id;

        $businessCount = Business::where('account_id', $accountId)->count();
        $userCount = User::where('account_id', $accountId)->count();

        // Get total orders across all businesses of this account
        $businessIds = Business::where('account_id', $accountId)->pluck('id');
        $ordersCount = \App\Models\Order::whereIn('business_id', $businessIds)->count();
        $devicesCount = \App\Models\Device::whereIn('business_id', $businessIds)->count();

        // Platform-level account stats
        $totalAccounts = \App\Models\Account::count();
        $activeAccounts = \App\Models\Account::where('status', 'Active')->count();
        $suspendedAccounts = \App\Models\Account::where('status', 'Suspended')->count();
        $closedAccounts = \App\Models\Account::where('status', 'Closed')->count();

        return response()->json([
            'data' => [
                'total_businesses' => $businessCount,
                'total_users' => $userCount,
                'total_orders' => $ordersCount,
                'total_devices' => $devicesCount,
                'accounts' => [
                    'total' => $totalAccounts,
                    'active' => $activeAccounts,
                    'suspended' => $suspendedAccounts,
                    'closed' => $closedAccounts,
                ],
            ]
        ]);
    }
}
