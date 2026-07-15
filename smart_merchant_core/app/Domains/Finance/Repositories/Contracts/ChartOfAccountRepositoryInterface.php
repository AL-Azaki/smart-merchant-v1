<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\DTOs\ChartOfAccountListCriteriaDTO;
use App\Domains\Finance\DTOs\ChartOfAccountSearchCriteriaDTO;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

interface ChartOfAccountRepositoryInterface
{
    public function create(array $data): ChartOfAccount;
    
    public function update(ChartOfAccount $account, array $data): ChartOfAccount;
    
    public function delete(ChartOfAccount $account): bool;
    
    public function findById(string $id): ?ChartOfAccount;
    
    public function findByCode(string $businessId, string $code): ?ChartOfAccount;
    
    public function paginate(ChartOfAccountListCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function search(ChartOfAccountSearchCriteriaDTO $criteria): LengthAwarePaginator;
    
    public function getTree(string $businessId): Collection;
    
    public function countChildren(string $id): int;
    
    public function hasJournalLines(string $id): bool;
    
    public function countRootAccounts(string $businessId): int;
}
