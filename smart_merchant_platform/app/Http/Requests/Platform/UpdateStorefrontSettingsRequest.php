<?php

namespace App\Http\Requests\Platform;

use App\Services\Storefront\StorefrontSettingsService;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStorefrontSettingsRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $merge = [];

        if ($this->has('storefront_slug') && is_string($this->input('storefront_slug'))) {
            $merge['storefront_slug'] = StorefrontSettingsService::normalizeSlug($this->input('storefront_slug'));
        }

        if ($this->has('storefront_display_name') && is_string($this->input('storefront_display_name'))) {
            $val = trim($this->input('storefront_display_name'));
            $merge['storefront_display_name'] = $val === '' ? null : $val;
        }

        if ($this->has('storefront_phone') && is_string($this->input('storefront_phone'))) {
            $val = trim($this->input('storefront_phone'));
            $merge['storefront_phone'] = $val === '' ? null : $val;
        }

        if ($this->has('storefront_whatsapp') && is_string($this->input('storefront_whatsapp'))) {
            $val = trim($this->input('storefront_whatsapp'));
            $merge['storefront_whatsapp'] = $val === '' ? null : $val;
        }

        if ($this->has('storefront_active')) {
            $val = $this->input('storefront_active');
            if (is_string($val)) {
                $filtered = filter_var($val, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                if ($filtered !== null) {
                    $merge['storefront_active'] = $filtered;
                }
            }
        }

        if (! empty($merge)) {
            $this->merge($merge);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $service = app(StorefrontSettingsService::class);
        $currentBusiness = $service->resolveBusiness($this);

        $isActive = filter_var($this->input('storefront_active'), FILTER_VALIDATE_BOOLEAN);

        $slugRules = [
            $isActive ? 'required' : 'nullable',
            'string',
            'min:3',
            'max:60',
            'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/',
            Rule::notIn(StorefrontSettingsService::RESERVED_SLUGS),
            Rule::unique('businesses', 'storefront_slug')->ignore($currentBusiness->id),
        ];

        return [
            'storefront_active' => ['required', 'boolean'],
            'storefront_display_name' => ['nullable', 'string', 'max:150'],
            'storefront_slug' => $slugRules,
            'storefront_whatsapp' => ['nullable', 'string', 'max:30'],
            'storefront_phone' => ['nullable', 'string', 'max:30'],
            'storefront_address_text' => ['nullable', 'string', 'max:500'],
            'storefront_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'storefront_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'storefront_theme_settings' => ['nullable', 'array'],
            'storefront_theme_settings.primary_color' => [
                'nullable',
                'string',
                'regex:/^#([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$/',
            ],
            'storefront_categories' => ['nullable', 'array'],
            'storefront_categories.*' => ['string', 'max:50'],
        ];
    }

    /**
     * Custom messages for validation errors.
     */
    public function messages(): array
    {
        return [
            'storefront_active.required' => 'حالة المتجر مطلوبة.',
            'storefront_active.boolean' => 'حالة المتجر يجب أن تكون قيمة منطقية (true أو false).',
            'storefront_slug.required' => 'رابط المتجر مطلوب عند تفعيل المتجر.',
            'storefront_slug.min' => 'رابط المتجر يجب ألا يقل عن 3 أحرف.',
            'storefront_slug.max' => 'رابط المتجر يجب ألا يتجاوز 60 حرفاً.',
            'storefront_slug.regex' => 'رابط المتجر يجب أن يتكون من أحرف إنجليزية صغيرة وأرقام وشرطات فقط، ولا يمكن أن يبدأ أو ينتهي بشرطة.',
            'storefront_slug.not_in' => 'رابط المتجر المختار محجوز للنظام، يرجى اختيار رابط آخر.',
            'storefront_slug.unique' => 'رابط المتجر محجوز بالفعل لمنشأة أخرى، يرجى اختيار رابط مختلف.',
            'storefront_lat.between' => 'خط العرض يجب أن يكون بين -90 و 90.',
            'storefront_lng.between' => 'خط الطول يجب أن يكون بين -180 و 180.',
            'storefront_theme_settings.primary_color.regex' => 'لون المتجر يجب أن يكون بصيغة HEX صالحة (مثل #2563EB).',
        ];
    }
}
