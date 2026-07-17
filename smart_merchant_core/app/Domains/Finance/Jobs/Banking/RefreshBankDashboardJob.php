<?php

namespace App\Domains\Finance\Jobs\Banking;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class RefreshBankDashboardJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public string $businessId;
    public string $accountId;

    public function __construct(string $businessId, string $accountId)
    {
        $this->businessId = $businessId;
        $this->accountId = $accountId;
    }

    public function handle(): void
    {
        // Background Processing Platform executes the actual dashboard refresh.
    }
}
