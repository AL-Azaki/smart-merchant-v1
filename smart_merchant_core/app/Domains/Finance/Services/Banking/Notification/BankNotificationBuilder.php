<?php

namespace App\Domains\Finance\Services\Banking\Notification;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Models\BankTransaction;
use App\Domains\Finance\DTOs\NotificationRequestDTO;

class BankNotificationBuilder
{
    /**
     * Builds a NotificationRequestDTO from a BankAccount event.
     */
    public function buildFromAccount(BankAccount $account, string $eventName): NotificationRequestDTO
    {
        $businessId = $account->business_id;
        $title = $this->resolveAccountTitle($eventName);
        $message = $this->resolveAccountMessage($account, $eventName);
        $level = $this->resolveAccountLevel($eventName);
        
        return new NotificationRequestDTO(
            businessId: $businessId,
            module: 'Banking',
            entityType: 'BankAccount',
            entityId: $account->id,
            title: $title,
            message: $message,
            level: $level,
            metadata: [
                'account_number' => $account->account_number,
                'bank_name' => $account->bank_name,
                'status' => $account->status,
            ]
        );
    }

    /**
     * Builds a NotificationRequestDTO from a BankTransaction event.
     */
    public function buildFromTransaction(BankTransaction $transaction, string $eventName): NotificationRequestDTO
    {
        $businessId = $transaction->business_id;
        $title = $this->resolveTransactionTitle($eventName);
        $message = $this->resolveTransactionMessage($transaction, $eventName);
        $level = $this->resolveTransactionLevel($eventName);
        
        return new NotificationRequestDTO(
            businessId: $businessId,
            module: 'Banking',
            entityType: 'BankTransaction',
            entityId: $transaction->id,
            title: $title,
            message: $message,
            level: $level,
            metadata: [
                'transaction_type' => $transaction->transaction_type,
                'direction' => $transaction->direction,
                'amount' => $transaction->amount,
            ]
        );
    }

    private function resolveAccountTitle(string $eventName): string
    {
        return match ($eventName) {
            'BankAccountFrozen' => 'Bank Account Frozen',
            'BankAccountClosed' => 'Bank Account Closed',
            default => 'Bank Account Updated',
        };
    }

    private function resolveAccountMessage(BankAccount $account, string $eventName): string
    {
        return match ($eventName) {
            'BankAccountFrozen' => "Bank Account {$account->account_number} ({$account->bank_name}) has been frozen.",
            'BankAccountClosed' => "Bank Account {$account->account_number} ({$account->bank_name}) has been closed.",
            default => "Bank Account {$account->account_number} has been updated.",
        };
    }
    
    private function resolveAccountLevel(string $eventName): string
    {
        return match ($eventName) {
            'BankAccountFrozen', 'BankAccountClosed' => 'warning',
            default => 'info',
        };
    }

    private function resolveTransactionTitle(string $eventName): string
    {
        return match ($eventName) {
            'BankTransactionCreated' => 'New Bank Transaction',
            default => 'Bank Transaction Alert',
        };
    }

    private function resolveTransactionMessage(BankTransaction $transaction, string $eventName): string
    {
        return match ($eventName) {
            'BankTransactionCreated' => "A new {$transaction->direction} transaction of {$transaction->amount} was recorded.",
            default => "A bank transaction alert was generated.",
        };
    }
    
    private function resolveTransactionLevel(string $eventName): string
    {
        return 'info';
    }
}
