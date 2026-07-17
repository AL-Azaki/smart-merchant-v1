<?php

namespace App\Domains\Finance\Contracts\Integration;

use App\Domains\Finance\DTOs\Integration\NotificationRequestDTO;

interface NotificationPlatformInterface
{
    public function dispatch(NotificationRequestDTO $request): void;
}
