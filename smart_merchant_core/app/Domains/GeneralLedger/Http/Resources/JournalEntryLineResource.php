<?php

namespace App\Domains\GeneralLedger\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class JournalEntryLineResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'journal_entry_id' => $this->journal_entry_id,
            'line_number' => $this->line_number,
            'chart_of_account_id' => $this->chart_of_account_id,
            'description' => $this->description,
            'currency_id' => $this->currency_id,
            'exchange_rate' => $this->exchange_rate,
            'type' => $this->type,
            'foreign_amount' => $this->foreign_amount,
            'base_amount' => $this->base_amount,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
        ];
    }
}
