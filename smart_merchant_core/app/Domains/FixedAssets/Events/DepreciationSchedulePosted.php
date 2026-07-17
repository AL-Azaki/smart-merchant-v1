<?php

namespace App\Domains\FixedAssets\Events;

use App\Domains\FixedAssets\Models\DepreciationSchedule;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DepreciationSchedulePosted
{
    use Dispatchable, SerializesModels;

    public DepreciationSchedule $schedule;

    public function __construct(DepreciationSchedule $schedule)
    {
        $this->schedule = $schedule;
    }
}
