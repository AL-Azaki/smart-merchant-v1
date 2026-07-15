<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Repositories\Contracts\BusinessRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateBusinessRecordAction
{
    public function __construct(private readonly BusinessRepositoryInterface $repository) {}

    public function handle(
        string $accountId,
        string $businessName,
        ?string $businessType,
        string $primaryPhone,
        string $primaryEmail,
        ?string $logoPath
    ): Business {
        if ($this->repository->existsByNameInAccount($accountId, $businessName)) {
            throw new CoreDomainException("A business with the name '{$businessName}' already exists in this account.");
        }

        return $this->repository->create([
            'account_id'    => $accountId,
            'business_name' => $businessName,
            'business_type' => $businessType,
            'primary_phone' => $primaryPhone,
            'primary_email' => $primaryEmail,
            'logo_path'     => $logoPath,
            'status'        => 'Active',
        ]);
    }
}
