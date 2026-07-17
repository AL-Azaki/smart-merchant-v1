<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use RuntimeException;

class GetSupplierStatementAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $payableId): array
    {
        $payable = $this->repository->loadAggregate($payableId);

        if (! $payable) {
            throw new RuntimeException("SupplierPayable not found.");
        }

        return [
            'supplier_payable' => $payable,
            'entries' => $payable->entries()->orderBy('created_at', 'asc')->get(),
            'statement_date' => now()->toIso8601String(),
        ];
    }
}
