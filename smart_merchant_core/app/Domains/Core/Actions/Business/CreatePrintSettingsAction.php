<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Extended\Repositories\Contracts\PrintSettingRepositoryInterface;

class CreatePrintSettingsAction
{
    public function __construct(private readonly PrintSettingRepositoryInterface $repository) {}

    public function handle(string $businessId, string $branchId)
    {
        return $this->repository->create([
            'business_id'    => $businessId,
            'branch_id'      => $branchId,
            'receipt_header' => 'Welcome to our store!',
            'receipt_footer' => 'Thank you for your visit.',
            'print_format'   => 'Thermal 80mm',
        ]);
    }
}
