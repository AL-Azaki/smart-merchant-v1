<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use RuntimeException;

class GetCustomerStatementAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $receivableId): array
    {
        $receivable = $this->repository->loadAggregate($receivableId);
        
        if (! $receivable) {
            throw new RuntimeException("CustomerReceivable not found.");
        }

        return [
            'customer_receivable' => $receivable,
            'entries' => $receivable->entries()->orderBy('created_at', 'asc')->get(),
            'statement_date' => now()->toIso8601String(),
        ];
    }
}
