<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Subscription;
use App\Domains\Core\DTOs\CreateBusinessDTO;
use App\Domains\Core\Repositories\Contracts\SubscriptionRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class CreateSubscriptionAction
{
    public function __construct(private readonly SubscriptionRepositoryInterface $repository) {}

    public function handle(Business $business, CreateBusinessDTO $dto): Subscription
    {
        $activeSub = $this->repository->findActiveByAccount($dto->accountId);

        if ($activeSub) {
            throw new CoreDomainException("This account already has an active subscription.");
        }

        return $this->repository->create([
            'account_id'  => $dto->accountId,
            'plan_id'     => $dto->planId,
            'start_date'  => now()->toDateString(),
            'end_date'    => now()->addDays(14)->toDateString(), // Default Trial period
            'amount_paid' => 0.00,
            'status'      => 'Active',
        ]);
    }
}
