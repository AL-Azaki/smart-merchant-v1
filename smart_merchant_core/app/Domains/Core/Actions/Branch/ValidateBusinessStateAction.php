<?php

namespace App\Domains\Core\Actions\Branch;

use App\Domains\Core\Repositories\Contracts\BusinessRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ValidateBusinessStateAction
{
    public function __construct(private readonly BusinessRepositoryInterface $repository) {}

    public function handle(string $businessId): void
    {
        $business = $this->repository->findById($businessId);

        if (!$business) {
            throw new CoreDomainException("The specified business does not exist.");
        }

        if ($business->status !== 'Active') {
            throw new CoreDomainException("Cannot create a branch for an inactive business.");
        }
    }
}
