<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Order;
use Illuminate\Http\Request;

class AdminOrderController extends Controller
{
    public function index(Request $request, Business $business)
    {
        $orders = $business->orders()->with('orderItems')->paginate(20);
        return response()->json($orders);
    }

    public function show(Request $request, Business $business, Order $order)
    {
        if ($order->business_id !== $business->id) {
            abort(404);
        }
        
        $order->load('orderItems');
        return response()->json(['data' => $order]);
    }
}
