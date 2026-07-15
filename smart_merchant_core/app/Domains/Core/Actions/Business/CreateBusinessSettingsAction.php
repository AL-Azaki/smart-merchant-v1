<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;
use App\Domains\Extended\Repositories\Contracts\SystemSettingRepositoryInterface;

class CreateBusinessSettingsAction
{
    public function __construct(private readonly SystemSettingRepositoryInterface $repository) {}

    public function handle(Business $business, ?string $timezone): array
    {
        $settings = [
            ['business_id' => $business->id, 'setting_key' => 'timezone', 'setting_value' => $timezone ?? 'UTC', 'setting_group' => 'general'],
            ['business_id' => $business->id, 'setting_key' => 'date_format', 'setting_value' => 'Y-m-d', 'setting_group' => 'general'],
            ['business_id' => $business->id, 'setting_key' => 'time_format', 'setting_value' => 'H:i:s', 'setting_group' => 'general'],
        ];

        return $this->repository->createMany($settings);
    }
}
