<?php

$dirs = [
    __DIR__.'/app/Http/Controllers/Api',
    __DIR__.'/app/Http/Requests',
    __DIR__.'/app/Http/Resources',
    __DIR__.'/app/Services',
    __DIR__.'/tests/Feature/Auth',
];

foreach ($dirs as $dir) {
    if (! is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
}

// 1. Requests
file_put_contents(__DIR__.'/app/Http/Requests/LoginRequest.php', <<<PHP
<?php
namespace App\Http\Requests;
use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules() {
        return [
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'nullable|string'
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Requests/RegisterDeviceRequest.php', <<<PHP
<?php
namespace App\Http\Requests;
use Illuminate\Foundation\Http\FormRequest;

class RegisterDeviceRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules() {
        return [
            'business_id' => 'required|uuid|exists:businesses,id',
            'device_uuid' => 'required|string|max:255',
            'device_name' => 'nullable|string|max:255',
            'platform' => 'nullable|string|max:100',
            'app_version' => 'nullable|string|max:50'
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Requests/BootstrapRequest.php', <<<PHP
<?php
namespace App\Http\Requests;
use Illuminate\Foundation\Http\FormRequest;

class BootstrapRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules() {
        return [
            'business_id' => 'nullable|uuid|exists:businesses,id',
            'branch_id' => 'nullable|uuid|exists:branches,id',
            'device_uuid' => 'nullable|string'
        ];
    }
}
PHP);

// 2. Resources
file_put_contents(__DIR__.'/app/Http/Resources/UserResource.php', <<<PHP
<?php
namespace App\Http\Resources;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'full_name' => \$this->full_name,
            'email' => \$this->email,
            'username' => \$this->username,
            'is_active' => \$this->is_active,
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Resources/BusinessResource.php', <<<PHP
<?php
namespace App\Http\Resources;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BusinessResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'business_name' => \$this->business_name,
            'business_type' => \$this->business_type,
            'status' => \$this->status,
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Resources/BranchResource.php', <<<PHP
<?php
namespace App\Http\Resources;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BranchResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'branch_name' => \$this->branch_name,
            'branch_code' => \$this->branch_code,
            'is_active' => \$this->is_active,
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Resources/DeviceResource.php', <<<PHP
<?php
namespace App\Http\Resources;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'device_uuid' => \$this->device_uuid,
            'device_name' => \$this->device_name,
            'platform' => \$this->platform,
            'status' => \$this->revoked_at ? 'revoked' : 'active',
        ];
    }
}
PHP);

// 3. Services
file_put_contents(__DIR__.'/app/Services/AuthService.php', <<<PHP
<?php
namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function login(string \$email, string \$password, ?string \$deviceName): array
    {
        \$user = User::where('email', \$email)->first();

        if (!\$user || !Hash::check(\$password, \$user->password_hash)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials provided.'],
            ]);
        }

        if (!\$user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['User account is inactive.'],
            ]);
        }

        \$user->update(['last_login_at' => now()]);

        \$tokenName = \$deviceName ?? 'default-device';
        \$token = \$user->createToken(\$tokenName)->plainTextToken;

        return [
            'user' => \$user,
            'token' => \$token
        ];
    }

    public function logout(User \$user): void
    {
        \$user->currentAccessToken()->delete();
    }
}
PHP);

file_put_contents(__DIR__.'/app/Services/SessionBootstrapService.php', <<<PHP
<?php
namespace App\Services;

use App\Models\User;
use App\Models\Business;
use App\Models\Device;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class SessionBootstrapService
{
    public function getBootstrapContext(User \$user, ?string \$requestedBusinessId, ?string \$requestedBranchId, ?string \$deviceUuid): array
    {
        // Resolve available businesses
        \$businesses = \$user->businesses()->where('status', 'Active')->get();
        if (\$businesses->isEmpty()) {
            throw new AccessDeniedHttpException('User does not belong to any active business.');
        }

        // Determine active business
        \$activeBusiness = null;
        if (\$requestedBusinessId) {
            \$activeBusiness = \$businesses->firstWhere('id', \$requestedBusinessId);
            if (!\$activeBusiness) {
                throw new AccessDeniedHttpException('Unauthorized access to requested business.');
            }
        } else {
            \$activeBusiness = \$businesses->first();
        }

        // Resolve branches
        \$branches = \$activeBusiness->branches()
            ->whereHas('users', function(\$q) use (\$user) {
                \$q->where('users.id', \$user->id);
            })->where('is_active', true)->get();

        // Determine active branch
        \$activeBranch = null;
        if (\$requestedBranchId) {
            \$activeBranch = \$branches->firstWhere('id', \$requestedBranchId);
            if (!\$activeBranch) {
                throw new AccessDeniedHttpException('Unauthorized access to requested branch.');
            }
        } else if (\$user->default_branch_id) {
            \$activeBranch = \$branches->firstWhere('id', \$user->default_branch_id);
        }
        
        if (!\$activeBranch && \$branches->isNotEmpty()) {
            \$activeBranch = \$branches->first();
        }

        // Resolve Roles & Permissions
        \$roles = \$user->roles()->where('business_id', \$activeBusiness->id)->with('permissions')->get();
        \$permissions = collect();
        foreach (\$roles as \$role) {
            foreach (\$role->permissions as \$perm) {
                \$permissions->push(\$perm->name);
            }
        }

        // Resolve Subscription
        \$subscription = \$activeBusiness->subscriptions()->where('status', 'Active')->with('plan')->first();

        // Resolve Device
        \$device = null;
        if (\$deviceUuid) {
            \$device = Device::where('business_id', \$activeBusiness->id)
                ->where('device_uuid', \$deviceUuid)
                ->first();
            
            if (\$device && \$device->revoked_at) {
                throw new AccessDeniedHttpException('Device has been revoked.');
            }
        }

        return [
            'user' => \$user,
            'active_business' => \$activeBusiness,
            'available_businesses' => \$businesses,
            'active_branch' => \$activeBranch,
            'allowed_branches' => \$branches,
            'roles' => \$roles->pluck('name'),
            'permissions' => \$permissions->unique()->values(),
            'subscription' => \$subscription,
            'device' => \$device,
        ];
    }
}
PHP);

file_put_contents(__DIR__.'/app/Services/DeviceRegistrationService.php', <<<PHP
<?php
namespace App\Services;

use App\Models\Device;
use App\Models\Business;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class DeviceRegistrationService
{
    public function register(User \$user, string \$businessId, string \$deviceUuid, ?string \$deviceName, ?string \$platform, ?string \$appVersion): Device
    {
        // Ensure user belongs to business
        if (!\$user->businesses()->where('businesses.id', \$businessId)->exists()) {
            throw new ValidationException::withMessages(['business_id' => 'Unauthorized business.']);
        }

        \$device = Device::where('business_id', \$businessId)
            ->where('device_uuid', \$deviceUuid)
            ->first();

        if (\$device) {
            if (\$device->revoked_at) {
                throw new ValidationException::withMessages(['device_uuid' => 'This device is revoked and cannot be registered again.']);
            }
            
            // Update last seen
            \$device->update([
                'device_name' => \$deviceName ?? \$device->device_name,
                'platform' => \$platform ?? \$device->platform,
                'app_version' => \$appVersion ?? \$device->app_version,
                'last_synced_at' => now(),
            ]);

            return \$device;
        }

        // Create new
        return Device::create([
            'business_id' => \$businessId,
            'user_id' => \$user->id,
            'device_uuid' => \$deviceUuid,
            'device_name' => \$deviceName,
            'platform' => \$platform,
            'app_version' => \$appVersion,
            'last_synced_at' => now(),
        ]);
    }
}
PHP);

// 4. Controllers
file_put_contents(__DIR__.'/app/Http/Controllers/Api/AuthController.php', <<<PHP
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AuthController extends Controller
{
    protected \$authService;

    public function __construct(AuthService \$authService)
    {
        \$this->authService = \$authService;
    }

    public function login(LoginRequest \$request): JsonResponse
    {
        \$result = \$this->authService->login(
            \$request->input('email'),
            \$request->input('password'),
            \$request->input('device_name')
        );

        return response()->json([
            'message' => 'Login successful',
            'token' => \$result['token'],
            'user' => new UserResource(\$result['user'])
        ]);
    }

    public function me(Request \$request): JsonResponse
    {
        return response()->json([
            'user' => new UserResource(\$request->user())
        ]);
    }

    public function logout(Request \$request): JsonResponse
    {
        \$this->authService->logout(\$request->user());

        return response()->json([
            'message' => 'Logged out successfully.'
        ]);
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Controllers/Api/SessionBootstrapController.php', <<<PHP
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BootstrapRequest;
use App\Services\SessionBootstrapService;
use App\Http\Resources\UserResource;
use App\Http\Resources\BusinessResource;
use App\Http\Resources\BranchResource;
use App\Http\Resources\DeviceResource;
use Illuminate\Http\JsonResponse;

class SessionBootstrapController extends Controller
{
    protected \$bootstrapService;

    public function __construct(SessionBootstrapService \$bootstrapService)
    {
        \$this->bootstrapService = \$bootstrapService;
    }

    public function bootstrap(BootstrapRequest \$request): JsonResponse
    {
        \$context = \$this->bootstrapService->getBootstrapContext(
            \$request->user(),
            \$request->input('business_id'),
            \$request->input('branch_id'),
            \$request->input('device_uuid')
        );

        return response()->json([
            'user' => new UserResource(\$context['user']),
            'active_business' => new BusinessResource(\$context['active_business']),
            'available_businesses' => BusinessResource::collection(\$context['available_businesses']),
            'active_branch' => \$context['active_branch'] ? new BranchResource(\$context['active_branch']) : null,
            'allowed_branches' => BranchResource::collection(\$context['allowed_branches']),
            'roles' => \$context['roles'],
            'permissions' => \$context['permissions'],
            'subscription' => \$context['subscription'] ? [
                'id' => \$context['subscription']->id,
                'status' => \$context['subscription']->status,
                'plan' => \$context['subscription']->plan ? \$context['subscription']->plan->plan_name : null,
                'ends_at' => \$context['subscription']->ends_at,
            ] : null,
            'device' => \$context['device'] ? new DeviceResource(\$context['device']) : null,
        ]);
    }
}
PHP);

file_put_contents(__DIR__.'/app/Http/Controllers/Api/DeviceController.php', <<<PHP
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterDeviceRequest;
use App\Http\Resources\DeviceResource;
use App\Services\DeviceRegistrationService;
use Illuminate\Http\JsonResponse;

class DeviceController extends Controller
{
    protected \$deviceService;

    public function __construct(DeviceRegistrationService \$deviceService)
    {
        \$this->deviceService = \$deviceService;
    }

    public function register(RegisterDeviceRequest \$request): JsonResponse
    {
        \$device = \$this->deviceService->register(
            \$request->user(),
            \$request->input('business_id'),
            \$request->input('device_uuid'),
            \$request->input('device_name'),
            \$request->input('platform'),
            \$request->input('app_version')
        );

        return response()->json([
            'message' => 'Device registered successfully',
            'device' => new DeviceResource(\$device)
        ]);
    }
}
PHP);

echo "Authentication files generated.\n";
