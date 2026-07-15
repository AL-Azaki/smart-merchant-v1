<?php

namespace App\Domains\Extended\Repositories\Eloquent;

use App\Domains\Extended\Models\SystemSetting;
use App\Domains\Extended\Repositories\Contracts\SystemSettingRepositoryInterface;

class SystemSettingEloquentRepository implements SystemSettingRepositoryInterface
{
    public function createMany(array $settings): array
    {
        $created = [];
        foreach ($settings as $settingData) {
            $created[] = SystemSetting::create($settingData);
        }
        return $created;
    }
}
