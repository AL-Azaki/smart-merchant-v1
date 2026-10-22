<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Storefront\MarketplaceQueryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MarketplaceController extends Controller
{
    public function __construct(
        protected MarketplaceQueryService $queryService
    ) {}

    /**
     * Public discovery endpoint for marketplace homepage.
     */
    public function explore(Request $request): JsonResponse
    {
        $data = $this->queryService->getExploreData($request);

        return response()->json($data);
    }
}
