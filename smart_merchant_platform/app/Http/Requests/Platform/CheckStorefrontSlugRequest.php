<?php

namespace App\Http\Requests\Platform;

use App\Services\Storefront\StorefrontSettingsService;
use Illuminate\Foundation\Http\FormRequest;

class CheckStorefrontSlugRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Prepare data for validation.
     */
    protected function prepareForValidation(): void
    {
        if ($this->has('slug') && is_string($this->input('slug'))) {
            $this->merge([
                'slug' => StorefrontSettingsService::normalizeSlug($this->input('slug')),
            ]);
        }
    }

    /**
     * Validation rules for slug availability check.
     */
    public function rules(): array
    {
        return [
            'slug' => [
                'required',
                'string',
                'min:3',
                'max:60',
                'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/',
            ],
        ];
    }

    /**
     * Custom messages.
     */
    public function messages(): array
    {
        return [
            'slug.required' => 'حقل رابط المتجر مطلوب للتحقق.',
            'slug.min' => 'رابط المتجر يجب ألا يقل عن 3 أحرف.',
            'slug.max' => 'رابط المتجر يجب ألا يتجاوز 60 حرفاً.',
            'slug.regex' => 'رابط المتجر يجب أن يتكون من أحرف إنجليزية صغيرة وأرقام وشرطات فقط، ولا يمكن أن يبدأ أو ينتهي بشرطة.',
        ];
    }
}
