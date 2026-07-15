<?php

namespace App\Domains\Purchasing\Policies;

use App\Domains\Core\Models\User;
use App\Domains\Purchasing\Models\PurchaseInvoice;

class PurchaseInvoicePolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, PurchaseInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, PurchaseInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Draft';
    }

    public function delete(User $user, PurchaseInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Draft';
    }

    public function post(User $user, PurchaseInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Draft';
    }

    public function reverse(User $user, PurchaseInvoice $invoice): bool
    {
        return $user->business_id === $invoice->business_id && $invoice->status === 'Posted';
    }
}
