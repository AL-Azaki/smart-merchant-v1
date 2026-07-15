<?php

namespace App\Domains\Finance\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ManualJournalLineResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'line_number' => $this->line_number,
            'chart_of_account_id' => $this->chart_of_account_id,
            'type' => $this->type,
            'foreign_amount' => $this->foreign_amount,
            'base_amount' => $this->base_amount,
            'description' => $this->description,
        ];
    }
}
