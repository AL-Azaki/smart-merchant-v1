<?php

namespace App\Domains\Extended\Repositories\Contracts;

interface PrintSettingRepositoryInterface
{
    public function create(array $data): mixed;
}
