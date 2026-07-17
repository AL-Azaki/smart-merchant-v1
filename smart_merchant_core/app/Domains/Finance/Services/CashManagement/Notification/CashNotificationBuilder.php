<?php

namespace App\Domains\Finance\Services\CashManagement\Notification;

use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Models\CashTransaction;
use App\Domains\Finance\DTOs\Integration\CashNotificationRequestDTO;

class CashNotificationBuilder
{
    /**
     * Builds a notification request from a CashRegister lifecycle event.
     * Contains NO business logic — pure data transformation only.
     */
    public function buildFromRegister(CashRegister $register, string $eventName): CashNotificationRequestDTO
    {
        $recipients = $this->resolveRegisterRecipients($register);
        $channels = $this->resolveChannels($eventName);

        return new CashNotificationRequestDTO(
            recipientIds: $recipients,
            channels: $channels,
            title: $this->resolveRegisterTitle($eventName),
            body: $this->resolveRegisterBody($register, $eventName),
            metadata: [
                'cash_register_id' => $register->id,
                'business_id' => $register->business_id,
                'branch_id' => $register->branch_id,
                'event' => $eventName,
            ]
        );
    }

    /**
     * Builds a notification request from a CashTransaction event.
     * Contains NO business logic — pure data transformation only.
     */
    public function buildFromTransaction(CashTransaction $transaction, string $eventName): CashNotificationRequestDTO
    {
        $recipients = $this->resolveTransactionRecipients($transaction);
        $channels = $this->resolveChannels($eventName);

        return new CashNotificationRequestDTO(
            recipientIds: $recipients,
            channels: $channels,
            title: $this->resolveTransactionTitle($eventName),
            body: $this->resolveTransactionBody($transaction, $eventName),
            metadata: [
                'cash_transaction_id' => $transaction->id,
                'cash_register_id' => $transaction->cash_register_id,
                'business_id' => $transaction->business_id,
                'transaction_type' => $transaction->transaction_type,
                'amount' => $transaction->amount,
                'event' => $eventName,
            ]
        );
    }

    private function resolveRegisterRecipients(CashRegister $register): array
    {
        $recipients = [];

        if ($register->created_by) {
            $recipients[] = $register->created_by;
        }

        if ($register->updated_by && $register->updated_by !== $register->created_by) {
            $recipients[] = $register->updated_by;
        }

        return array_unique(array_filter($recipients));
    }

    private function resolveTransactionRecipients(CashTransaction $transaction): array
    {
        $recipients = [];

        if ($transaction->created_by) {
            $recipients[] = $transaction->created_by;
        }

        return array_unique(array_filter($recipients));
    }

    private function resolveChannels(string $eventName): array
    {
        // High-importance events use In-App + Push
        // Standard events use In-App only
        $highImportance = ['CashRegisterClosed', 'CashTransactionReversed'];

        if (in_array($eventName, $highImportance)) {
            return ['In-App', 'Push'];
        }

        return ['In-App'];
    }

    private function resolveRegisterTitle(string $eventName): string
    {
        return match ($eventName) {
            'CashRegisterOpened' => 'Cash Register Opened',
            'CashRegisterClosed' => 'Cash Register Closed',
            default => 'Cash Register Updated',
        };
    }

    private function resolveRegisterBody(CashRegister $register, string $eventName): string
    {
        return match ($eventName) {
            'CashRegisterOpened' => "Cash Register \"{$register->register_name}\" has been opened.",
            'CashRegisterClosed' => "Cash Register \"{$register->register_name}\" has been closed.",
            default => "Cash Register \"{$register->register_name}\" status has changed.",
        };
    }

    private function resolveTransactionTitle(string $eventName): string
    {
        return match ($eventName) {
            'CashTransactionCreated' => 'New Cash Transaction',
            'CashTransactionReversed' => 'Cash Transaction Reversed',
            default => 'Cash Transaction Updated',
        };
    }

    private function resolveTransactionBody(CashTransaction $transaction, string $eventName): string
    {
        return match ($eventName) {
            'CashTransactionCreated' => "A new cash transaction of {$transaction->amount} ({$transaction->transaction_type}) has been recorded.",
            'CashTransactionReversed' => "Cash transaction of {$transaction->amount} ({$transaction->transaction_type}) has been reversed.",
            default => "Cash transaction has been updated.",
        };
    }
}
