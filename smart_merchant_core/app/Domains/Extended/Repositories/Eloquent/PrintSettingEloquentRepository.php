<?php

namespace App\Domains\Extended\Repositories\Eloquent;

use App\Domains\Extended\Models\PrintSetting;
use App\Domains\Extended\Repositories\Contracts\PrintSettingRepositoryInterface;

class PrintSettingEloquentRepository implements PrintSettingRepositoryInterface
{
    public function create(array $data): PrintSetting
    {
        return PrintSetting::create($data);
    }
}
