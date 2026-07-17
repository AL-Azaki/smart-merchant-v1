<?php

namespace App\Domains\FixedAssets\Services\Integration\FinancialClosing;

use App\Domains\FinancialClosing\Services\Integration\PeriodPostingAuthorizationService;
use RuntimeException;

class DepreciationPostingAuthorizationService
{
    private PeriodPostingAuthorizationService $periodAuthService;

    public function __construct(PeriodPostingAuthorizationService $periodAuthService)
    {
        $this->periodAuthService = $periodAuthService;
    }

    /**
     * Verify that the accounting period for a given posting date is OPEN.
     * If the period is closed, depreciation posting must be rejected.
     *
     * @throws RuntimeException if the period is closed or not found.
     */
    public function authorize(string $businessId, string $postingDate): bool
    {
        $isAuthorized = $this->periodAuthService->isPostingAuthorized($businessId, $postingDate);

        if (!$isAuthorized) {
            throw new RuntimeException(
                "Depreciation posting rejected: The accounting period for [{$postingDate}] is closed or does not exist."
            );
        }

        return true;
    }
}
