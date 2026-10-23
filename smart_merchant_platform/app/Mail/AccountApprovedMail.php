<?php

namespace App\Mail;

use App\Models\Account;
use App\Models\Subscription;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AccountApprovedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $account;
    public $subscription;

    public function __construct(Account $account, ?Subscription $subscription = null)
    {
        $this->account = $account;
        $this->subscription = $subscription;
    }

    public function build()
    {
        $business = $this->account->businesses()->first();
        $user = $this->account->users()->first();
        $subscription = $this->subscription ?? $this->account->subscriptions()->where('status', 'Active')->with(['plan', 'installments'])->latest()->first();

        return $this->subject('تهانينا! تم تفعيل حساب متجركم واعتماد عقد الاشتراك في تاجركم 🌟')
                    ->view('emails.account_approved')
                    ->with([
                        'account' => $this->account,
                        'business' => $business,
                        'user' => $user,
                        'subscription' => $subscription,
                        'installments' => $subscription ? $subscription->installments : collect(),
                    ]);
    }
}
