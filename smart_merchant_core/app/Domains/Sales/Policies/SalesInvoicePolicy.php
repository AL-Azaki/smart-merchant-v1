<?php

namespace App\Domains\Sales\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Sales\Models\SalesInvoice;

class SalesInvoicePolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, SalesInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, SalesInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Draft';
    }

    public function delete(User $user, SalesInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Draft';
    }
}
