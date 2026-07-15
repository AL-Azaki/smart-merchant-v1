<?php

namespace App\Domains\Extended\Repositories\Contracts;

interface SystemSettingRepositoryInterface
{
    public function createMany(array $settings): array;
}
