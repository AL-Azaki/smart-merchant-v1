<?php

namespace App\Domains\GeneralLedger\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReverseJournalEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => 'required|uuid|exists:users,id',
            'journal_number' => 'nullable|string|max:50',
            'document_date' => 'nullable|date',
            'posting_date' => 'nullable|date',
        ];
    }
}
