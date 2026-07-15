<?php

namespace App\Domains\Finance\Actions\AccountType;

use App\Domains\Finance\Repositories\Contracts\AccountTypeRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;

class ListAccountTypesAction
{
    public function __construct(private readonly AccountTypeRepositoryInterface $repository) {}

    public function handle(): Collection
    {
        return $this->repository->getAllActive();
    }
}
