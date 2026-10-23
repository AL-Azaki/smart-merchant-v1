<?php

namespace App\Mail;

use App\Models\Account;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AccountApprovedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $account;

    public function __construct(Account $account)
    {
        $this->account = $account;
    }

    public function build()
    {
        $business = $this->account->businesses()->first();
        $user = $this->account->users()->first();

        return $this->subject('تهانينا! تم تفعيل حساب متجركم بنجاح في منصة تاجركم 🌟')
                    ->view('emails.account_approved')
                    ->with([
                        'account' => $this->account,
                        'business' => $business,
                        'user' => $user,
                    ]);
    }
}
