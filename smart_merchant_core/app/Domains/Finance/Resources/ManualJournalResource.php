<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ManualJournalResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'journal_number' => $this->journal_number,
            'journal_type' => $this->journal_type,
            'status' => $this->status,
            'document_date' => $this->document_date->toDateString(),
            'posting_date' => $this->posting_date ? $this->posting_date->toDateString() : null,
            'currency_id' => $this->currency_id,
            'exchange_rate' => $this->exchange_rate,
            'description' => $this->description,
            'audit_trail' => [
                'created_by' => $this->created_by,
                'posted_by' => $this->posted_by,
                'reversed_by' => $this->reversed_by,
                'created_at' => $this->created_at ? $this->created_at->toIso8601String() : null,
                'posted_at' => $this->posted_at ? $this->posted_at->toIso8601String() : null,
                'reversed_at' => $this->reversed_at ? $this->reversed_at->toIso8601String() : null,
            ],
            'lines' => ManualJournalLineResource::collection($this->whenLoaded('lines')),
        ];
    }
}
