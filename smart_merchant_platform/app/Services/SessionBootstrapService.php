<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Device;
use App\Models\User;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class SessionBootstrapService
{
    public function getBootstrapContext(User $user, ?string $requestedBusinessId, ?string $requestedBranchId, ?string $deviceUuid): array
    {
        // Resolve available businesses
        $businesses = $user->businesses()->where('status', 'Active')->get();
        if ($businesses->isEmpty()) {
            throw new AccessDeniedHttpException('User does not belong to any active business.');
        }

        // Determine active business
        $activeBusiness = null;
        if ($requestedBusinessId) {
            $activeBusiness = $businesses->firstWhere('id', $requestedBusinessId);
            if (! $activeBusiness) {
                throw new AccessDeniedHttpException('Unauthorized access to requested business.');
            }
        } else {
            $activeBusiness = $businesses->first();
        }

        // Resolve branches
        $branches = $activeBusiness->branches()
            ->whereHas('users', function ($q) use ($user) {
                $q->where('users.id', $user->id);
            })->where('is_active', true)->get();

        // Determine active branch
        $activeBranch = null;
        if ($requestedBranchId) {
            $activeBranch = $branches->firstWhere('id', $requestedBranchId);
            if (! $activeBranch) {
                throw new AccessDeniedHttpException('Unauthorized access to requested branch.');
            }
        } elseif ($user->default_branch_id) {
            $activeBranch = $branches->firstWhere('id', $user->default_branch_id);
        }

        if (! $activeBranch && $branches->isNotEmpty()) {
            $activeBranch = $branches->first();
        }

        // Resolve Roles & Permissions
        $roles = $user->roles()->where('business_id', $activeBusiness->id)->with('permissions')->get();
        $permissions = collect();
        foreach ($roles as $role) {
            foreach ($role->permissions as $perm) {
                $permissions->push($perm->permission_code);
            }
        }

        // Resolve Subscription
        $subscription = $activeBusiness->account->subscriptions()->where('status', 'Active')->with('plan')->first();

        // Resolve Device
        $device = null;
        if ($deviceUuid) {
            $device = Device::where('business_id', $activeBusiness->id)
                ->where('device_uuid', $deviceUuid)
                ->first();

            if ($device && $device->revoked_at) {
                throw new AccessDeniedHttpException('Device has been revoked.');
            }
        }

        return [
            'user' => $user,
            'active_business' => $activeBusiness,
            'available_businesses' => $businesses,
            'active_branch' => $activeBranch,
            'allowed_branches' => $branches,
            'roles' => $roles->pluck('role_name'),
            'permissions' => $permissions->unique()->values(),
            'subscription' => $subscription,
            'device' => $device,
        ];
    }
}
