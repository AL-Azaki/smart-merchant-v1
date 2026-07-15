<?php

namespace App\Domains\Finance\Repositories\Contracts;

use App\Domains\Finance\Models\Payment;
use Illuminate\Support\Collection;

interface PaymentRepositoryInterface
{
    public function create(array $data): Payment;
    public function update(string $id, array $data): Payment;
    public function delete(string $id): bool;
    public function findById(string $id): ?Payment;
    public function findByNumber(string $businessId, string $paymentNumber): ?Payment;
    public function list(string $businessId, array $filters = []): Collection;
    public function loadAggregate(string $id): ?Payment;
}
