<?php

namespace App\Domains\FinancialClosing\Services\Integration\Notification;

use App\Domains\FinancialClosing\Models\AccountingPeriod;

class PeriodNotificationBuilder
{
    public function buildClosedNotification(AccountingPeriod $period): array
    {
        return [
            'business_id' => $period->business_id,
            'module' => 'FinancialClosing',
            'entity_type' => 'AccountingPeriod',
            'entity_id' => $period->id,
            'title' => 'Accounting Period Closed',
            'message' => "Accounting period '{$period->period_name}' has been closed.",
            'level' => 'warning',
            'metadata' => [
                'period_name' => $period->period_name,
                'status' => $period->status,
                'closed_by' => $period->closed_by,
                'closed_at' => $period->closed_at?->toIso8601String(),
            ],
        ];
    }

    public function buildReopenedNotification(AccountingPeriod $period, string $reason): array
    {
        return [
            'business_id' => $period->business_id,
            'module' => 'FinancialClosing',
            'entity_type' => 'AccountingPeriod',
            'entity_id' => $period->id,
            'title' => 'Accounting Period Reopened',
            'message' => "Accounting period '{$period->period_name}' has been reopened. Reason: {$reason}",
            'level' => 'critical',
            'metadata' => [
                'period_name' => $period->period_name,
                'status' => $period->status,
                'reopened_by' => $period->reopened_by,
                'reopened_at' => $period->reopened_at?->toIso8601String(),
                'reason' => $reason,
            ],
        ];
    }
}
