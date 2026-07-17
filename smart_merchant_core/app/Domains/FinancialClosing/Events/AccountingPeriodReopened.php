<?php

namespace App\Domains\FinancialClosing\Events;

use App\Domains\FinancialClosing\Models\AccountingPeriod;

class AccountingPeriodReopened
{
    public AccountingPeriod $period;
    public string $userId;
    public string $reason;

    public function __construct(AccountingPeriod $period, string $userId, string $reason)
    {
        $this->period = $period;
        $this->userId = $userId;
        $this->reason = $reason;
    }
}
