<?php

namespace App\Domains\FinancialClosing\Events;

use App\Domains\FinancialClosing\Models\AccountingPeriod;

class AccountingPeriodClosed
{
    public AccountingPeriod $period;
    public string $userId;

    public function __construct(AccountingPeriod $period, string $userId)
    {
        $this->period = $period;
        $this->userId = $userId;
    }
}
