<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthorizeBusinessAdmin
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $business = $request->route('business');
        if (is_string($business)) {
            $business = \App\Models\Business::find($business);
        }

        if (!$business) {
            return response()->json(['message' => 'Business not found'], 404);
        }

        $user = $request->user();

        // Check if user belongs to the same account as the business
        if ($user->account_id !== $business->account_id) {
            return response()->json(['message' => 'Unauthorized access to business'], 403);
        }

        // For now, if they share the account, we treat them as authorized for Admin API.
        // In a more granular setup, we'd check $user->roles() for "Business Admin".

        return $next($request);
    }
}
