<?php

namespace App\Domains\Finance\Events\CashManagement;

use App\Domains\Finance\Models\CashTransaction;

class CashTransactionReversed
{
    public CashTransaction $transaction;

    public function __construct(CashTransaction $transaction)
    {
        $this->transaction = $transaction;
    }
}
