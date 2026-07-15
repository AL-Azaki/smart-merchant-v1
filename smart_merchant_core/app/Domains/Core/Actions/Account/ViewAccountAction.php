<?php

namespace App\Domains\Core\Actions\Account;

use App\Models\Core\Account;
use App\Domains\Core\DTOs\ViewAccountDTO;
use App\Domains\Core\Repositories\Contracts\AccountRepositoryInterface;
use App\Domains\Core\Exceptions\CoreDomainException;

class ViewAccountAction
{
    private const ALLOWED_INCLUDES = ['businesses', 'subscriptions'];

    public function __construct(private readonly AccountRepositoryInterface $repository) {}

    public function handle(ViewAccountDTO $dto): Account
    {
        $validIncludes = array_intersect($dto->includes, self::ALLOWED_INCLUDES);
        $account = $this->repository->findByIdWithRelations($dto->accountId, $validIncludes);

        if (!$account) {
            throw new CoreDomainException("The specified account does not exist.");
        }

        return $account;
    }
}
