<?php

namespace App\Services\Storefront;

use App\Models\Business;
use App\Models\Device;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class StorefrontSettingsService
{
    /**
     * Reserved keywords that cannot be used as a storefront slug.
     */
    public const RESERVED_SLUGS = [
        'admin',
        'api',
        'app',
        'assets',
        'auth',
        'bootstrap',
        'cart',
        'checkout',
        'dashboard',
        'device',
        'devices',
        'health',
        'login',
        'logout',
        'media',
        'order',
        'orders',
        'platform',
        'product',
        'products',
        'register',
        'root',
        'session',
        'settings',
        'shop',
        'status',
        'storage',
        'store',
        'storefront',
        'subscription',
        'subscriptions',
        'sync',
        'user',
        'users',
        'vendor',
    ];

    /**
     * Resolves the authoritative current business for an authenticated request.
     */
    public function resolveBusiness(Request $request): Business
    {
        $user = $request->user();
        if (! $user) {
            abort(401, 'Unauthenticated');
        }

        // 1. If X-Device-ID header is provided (from Flutter POS / Mobile client)
        $deviceUuid = $request->header('X-Device-ID');
        if ($deviceUuid) {
            $device = Device::where('device_uuid', $deviceUuid)
                ->where('user_id', $user->id)
                ->first();

            if ($device && ! $device->revoked_at && ! $device->trashed()) {
                $business = Business::where('id', $device->business_id)->first();
                if ($business && ($business->account_id === $user->account_id || $user->businesses()->where('businesses.id', $business->id)->exists())) {
                    return $business;
                }
            }
        }

        // 2. If explicit X-Business-ID header or request input is provided
        $explicitBusinessId = $request->header('X-Business-ID') ?: $request->input('business_id');
        if ($explicitBusinessId) {
            $business = Business::where('id', $explicitBusinessId)->first();
            if ($business && ($business->account_id === $user->account_id || $user->businesses()->where('businesses.id', $business->id)->exists())) {
                return $business;
            }
            throw new AccessDeniedHttpException('Unauthorized access to the requested business.');
        }

        // 3. Fallback to user's branch / active business
        if ($user->default_branch_id && $user->defaultBranch && $user->defaultBranch->business) {
            return $user->defaultBranch->business;
        }

        $business = Business::where('account_id', $user->account_id)
            ->where('status', 'Active')
            ->first();

        if (! $business) {
            $business = Business::where('account_id', $user->account_id)->first();
        }

        if (! $business) {
            $business = $user->businesses()->where('status', 'Active')->first()
                ?: $user->businesses()->first();
        }

        if (! $business) {
            throw new AccessDeniedHttpException('No active business found for this account.');
        }

        return $business;
    }

    /**
     * Normalizes a slug string into canonical lowercase hyphenated form.
     */
    public static function normalizeSlug(?string $slug): ?string
    {
        if ($slug === null) {
            return null;
        }

        $trimmed = trim($slug);
        if ($trimmed === '') {
            return null;
        }

        $lower = Str::lower($trimmed);

        // Replace spaces, underscores and multiple hyphens with a single hyphen
        $slugified = preg_replace('/[\s_]+/', '-', $lower);
        $slugified = preg_replace('/-+/', '-', $slugified);
        $slugified = trim($slugified, '-');

        return $slugified === '' ? null : $slugified;
    }

    /**
     * Checks if a slug is in the reserved keywords list.
     */
    public static function isReservedSlug(string $slug): bool
    {
        return in_array(strtolower($slug), self::RESERVED_SLUGS, true);
    }

    /**
     * Checks availability of a given slug for the current business.
     */
    public function checkSlugAvailability(Business $currentBusiness, ?string $rawSlug): array
    {
        $normalized = self::normalizeSlug($rawSlug);

        // Validate syntax
        if (! $normalized || ! preg_match('/^[a-z0-9]+(?:-[a-z0-9]+)*$/', $normalized) || strlen($normalized) < 3 || strlen($normalized) > 60) {
            throw ValidationException::withMessages([
                'slug' => ['رابط المتجر يجب أن يتكون من 3 إلى 60 حرفاً، ويحتوي فقط على أحرف إنجليزية صغيرة وأرقام وشرطات دون أن يبدأ أو ينتهي بشرطة.'],
            ]);
        }

        // Reserved slugs check
        if (self::isReservedSlug($normalized)) {
            return [
                'slug' => $normalized,
                'available' => false,
                'store_url' => null,
            ];
        }

        // Check uniqueness excluding current business
        $exists = Business::where('storefront_slug', $normalized)
            ->where('id', '!=', $currentBusiness->id)
            ->exists();

        $available = ! $exists;

        return [
            'slug' => $normalized,
            'available' => $available,
            'store_url' => $available ? self::buildStoreUrl($normalized) : null,
        ];
    }

    /**
     * Builds the public storefront URL for a given slug using the configured STOREFRONT_URL.
     */
    public static function buildStoreUrl(?string $slug): ?string
    {
        if (empty($slug)) {
            return null;
        }

        $normalized = self::normalizeSlug($slug);
        if (empty($normalized)) {
            return null;
        }

        $baseUrl = rtrim((string) config('storefront.url', 'http://localhost:3000'), '/');

        return "{$baseUrl}/store/{$normalized}";
    }

    /**
     * Updates storefront settings for the current business with validation and idempotency.
     */
    public function updateSettings(Business $business, array $data): Business
    {
        $isActive = (bool) ($data['storefront_active'] ?? false);
        $rawSlug = $data['storefront_slug'] ?? $business->storefront_slug;
        $normalizedSlug = self::normalizeSlug($rawSlug);

        // Parse optional overrides (convert empty strings to null to restore fallback)
        $displayName = array_key_exists('storefront_display_name', $data)
            ? (trim((string) $data['storefront_display_name']) === '' ? null : trim((string) $data['storefront_display_name']))
            : $business->storefront_display_name;

        // Clean WhatsApp / phone if provided
        $whatsapp = array_key_exists('storefront_whatsapp', $data)
            ? $this->sanitizePhone($data['storefront_whatsapp'])
            : $business->storefront_whatsapp;

        $phone = array_key_exists('storefront_phone', $data)
            ? $this->sanitizePhone($data['storefront_phone'])
            : $business->storefront_phone;

        // If activating, enforce mandatory requirements
        if ($isActive) {
            $errors = [];

            if (empty($normalizedSlug)) {
                $errors['storefront_slug'] = ['لا يمكن تفعيل المتجر بدون تحديد رابط (Slug) صالح.'];
            } elseif (self::isReservedSlug($normalizedSlug)) {
                $errors['storefront_slug'] = ['رابط المتجر المختار محجوز للنظام، يرجى اختيار رابط آخر.'];
            }

            $effectiveName = ! empty($displayName)
                ? $displayName
                : (! empty($business->business_name) ? trim($business->business_name) : null);

            if (empty($effectiveName)) {
                $errors['storefront_display_name'] = ['يجب توفير اسم معتمد للمتجر لتفعيله.'];
            }

            $hasContact = ! empty($whatsapp)
                || ! empty($phone)
                || ! empty($business->primary_phone);

            if (! $hasContact) {
                $errors['storefront_whatsapp'] = ['يجب توفير وسيلة تواصل واحدة على الأقل (واتساب أو هاتف) لتفعيل المتجر للعملاء.'];
            }

            if (! empty($errors)) {
                throw ValidationException::withMessages($errors);
            }
        }

        $updatePayload = [
            'storefront_active' => $isActive,
            'storefront_slug' => $normalizedSlug,
            'storefront_display_name' => $displayName,
            'storefront_whatsapp' => $whatsapp,
            'storefront_phone' => $phone,
            'storefront_address_text' => array_key_exists('storefront_address_text', $data) ? $data['storefront_address_text'] : $business->storefront_address_text,
            'storefront_lat' => array_key_exists('storefront_lat', $data) ? $data['storefront_lat'] : $business->storefront_lat,
            'storefront_lng' => array_key_exists('storefront_lng', $data) ? $data['storefront_lng'] : $business->storefront_lng,
            'storefront_theme_settings' => array_key_exists('storefront_theme_settings', $data) ? $data['storefront_theme_settings'] : $business->storefront_theme_settings,
        ];

        try {
            $business->update($updatePayload);
        } catch (QueryException $e) {
            // Catch unique constraint collision
            if (str_contains($e->getMessage(), 'unique') || str_contains($e->getMessage(), 'Unique') || $e->getCode() == 23000 || $e->getCode() == 23505) {
                throw ValidationException::withMessages([
                    'storefront_slug' => ['رابط المتجر محجوز بالفعل لمنشأة أخرى، يرجى اختيار رابط مختلف.'],
                ]);
            }
            throw $e;
        }

        return $business->fresh();
    }

    /**
     * Sanitizes phone / whatsapp numbers preserving international prefix if present.
     */
    protected function sanitizePhone(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }

        $trimmed = trim($phone);
        if ($trimmed === '') {
            return null;
        }

        $hasPlus = str_starts_with($trimmed, '+');
        $digitsOnly = preg_replace('/[^\d]/', '', $trimmed);

        if ($digitsOnly === '') {
            return null;
        }

        return ($hasPlus ? '+' : '').$digitsOnly;
    }
}
