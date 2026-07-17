<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ActivateProductRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array { return []; }
}



