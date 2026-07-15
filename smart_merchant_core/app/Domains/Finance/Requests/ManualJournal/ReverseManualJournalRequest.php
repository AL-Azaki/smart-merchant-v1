<?php

namespace App\Domains\Finance\Requests\ManualJournal;

use Illuminate\Foundation\Http\FormRequest;

class ReverseManualJournalRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'posting_date' => 'required|date',
            'description' => 'nullable|string|max:1000',
        ];
    }
}
