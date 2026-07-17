<?php

namespace App\Domains\Finance\Events\CashManagement;

use App\Domains\Finance\Models\CashRegister;

class CashRegisterOpened
{
    public CashRegister $cashRegister;

    public function __construct(CashRegister $cashRegister)
    {
        $this->cashRegister = $cashRegister;
    }
}
