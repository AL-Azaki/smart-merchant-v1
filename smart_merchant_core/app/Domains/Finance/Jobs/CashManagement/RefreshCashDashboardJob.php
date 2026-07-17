<?php

namespace App\Domains\Finance\Jobs\CashManagement;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class RefreshCashDashboardJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public string $businessId;
    public string $registerId;

    public function __construct(string $businessId, string $registerId)
    {
        $this->businessId = $businessId;
        $this->registerId = $registerId;
    }

    public function handle(): void
    {
        // Background Processing Platform executes the actual dashboard refresh.
        // Implementation resides inside Background Processing Platform, not Cash Management.
    }
}
