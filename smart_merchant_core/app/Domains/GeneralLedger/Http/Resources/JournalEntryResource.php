<?php

namespace App\Domains\GeneralLedger\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class JournalEntryResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'business_id' => $this->business_id,
            'fiscal_year_id' => $this->fiscal_year_id,
            'fiscal_period_id' => $this->fiscal_period_id,
            'journal_number' => $this->journal_number,
            'document_date' => $this->document_date,
            'posting_date' => $this->posting_date,
            'journal_type' => $this->journal_type,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'document_number' => $this->document_number,
            'original_journal_id' => $this->original_journal_id,
            'currency_id' => $this->currency_id,
            'exchange_rate' => $this->exchange_rate,
            'description' => $this->description,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'posted_by' => $this->posted_by,
            'reversed_by' => $this->reversed_by,
            'posted_at' => $this->posted_at,
            'reversed_at' => $this->reversed_at,
            'lines' => JournalEntryLineResource::collection($this->whenLoaded('lines')),
        ];
    }
}
