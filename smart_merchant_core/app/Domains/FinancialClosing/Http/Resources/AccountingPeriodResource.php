<?php

namespace App\Domains\FinancialClosing\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class AccountingPeriodResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'fiscal_year_id' => $this->fiscal_year_id,
            'period_name' => $this->period_name,
            'start_date' => $this->start_date,
            'end_date' => $this->end_date,
            'status' => $this->status,
            'closed_by' => $this->closed_by,
            'closed_at' => $this->closed_at,
            'reopened_by' => $this->reopened_by,
            'reopened_at' => $this->reopened_at,
            'reopen_reason' => $this->reopen_reason,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
