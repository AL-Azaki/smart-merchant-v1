<?php

namespace App\Domains\Finance\Actions\AccountType;

use App\Domains\Finance\DTOs\ViewAccountTypeDTO;
use App\Domains\Finance\Models\AccountType;
use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class ViewAccountTypeAction
{
    public function __construct(private readonly AccountTypeRepositoryInterface $repository) {}

    public function handle(ViewAccountTypeDTO $dto): AccountType
    {
        $accountType = $this->repository->findById($dto->id);

        if (!$accountType) {
            throw new ModelNotFoundException("Account Type not found.");
        }

        return $accountType;
    }
}
