<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Finance\Repositories\Contracts\TaxRepositoryInterface;

class CreateDefaultTaxesAction
{
    public function __construct(private readonly TaxRepositoryInterface $repository) {}

    public function handle(string $businessId): array
    {
        $defaultTaxes = [
            ['business_id' => $businessId, 'tax_name' => 'VAT 15%', 'tax_rate' => 15.00, 'is_active' => true],
            ['business_id' => $businessId, 'tax_name' => 'Zero Tax', 'tax_rate' => 0.00, 'is_active' => true],
        ];

        return $this->repository->createMany($defaultTaxes);
    }
}
