<?php

namespace App\Domains\Catalog\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ViewproductUnitUnitRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array { return []; }
}




