<?php

namespace App\Http\Controllers\Api\Platform;

use App\Http\Controllers\Controller;
use App\Http\Requests\Platform\CheckStorefrontSlugRequest;
use App\Http\Requests\Platform\UpdateStorefrontSettingsRequest;
use App\Http\Resources\Platform\StorefrontSettingsResource;
use App\Services\Storefront\StorefrontSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StorefrontSettingsController extends Controller
{
    public function __construct(
        protected StorefrontSettingsService $settingsService
    ) {}

    /**
     * GET /api/platform/storefront/settings
     * Read storefront settings for the authenticated business.
     */
    public function show(Request $request): JsonResponse
    {
        $business = $this->settingsService->resolveBusiness($request);

        return response()->json([
            'success' => true,
            'data' => new StorefrontSettingsResource($business),
        ]);
    }

    /**
     * PUT /api/platform/storefront/settings
     * Update storefront settings for the authenticated business.
     */
    public function update(UpdateStorefrontSettingsRequest $request): JsonResponse
    {
        $business = $this->settingsService->resolveBusiness($request);

        $updated = $this->settingsService->updateSettings($business, $request->validated());

        return response()->json([
            'success' => true,
            'data' => new StorefrontSettingsResource($updated),
        ]);
    }

    /**
     * GET /api/platform/storefront/slug-availability
     * Check if a slug is available for the authenticated business.
     */
    public function checkSlugAvailability(CheckStorefrontSlugRequest $request): JsonResponse
    {
        $business = $this->settingsService->resolveBusiness($request);

        $result = $this->settingsService->checkSlugAvailability($business, $request->validated('slug'));

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }
}
