<?php

namespace App\Domains\Finance\Repositories\Eloquent;

use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class PaymentEloquentRepository implements PaymentRepositoryInterface
{
    public function create(array $data): Payment
    {
        return DB::transaction(function () use ($data) {
            $payment = Payment::create($data);
            
            if (isset($data['allocations']) && is_array($data['allocations'])) {
                $payment->allocations()->createMany($data['allocations']);
            }

            return $payment;
        });
    }

    public function update(string $id, array $data): Payment
    {
        return DB::transaction(function () use ($id, $data) {
            $payment = Payment::findOrFail($id);
            $payment->update($data);

            if (isset($data['allocations']) && is_array($data['allocations'])) {
                $payment->allocations()->delete();
                $payment->allocations()->createMany($data['allocations']);
            }

            return $payment;
        });
    }

    public function delete(string $id): bool
    {
        return DB::transaction(function () use ($id) {
            $payment = Payment::findOrFail($id);
            $payment->allocations()->delete();
            return $payment->delete();
        });
    }

    public function findById(string $id): ?Payment
    {
        return Payment::find($id);
    }

    public function findByNumber(string $businessId, string $paymentNumber): ?Payment
    {
        return Payment::where('business_id', $businessId)
            ->where('payment_number', $paymentNumber)
            ->first();
    }

    public function list(string $businessId, array $filters = []): Collection
    {
        $query = Payment::where('business_id', $businessId);

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['payment_type'])) {
            $query->where('payment_type', $filters['payment_type']);
        }

        if (isset($filters['contact_type']) && isset($filters['contact_id'])) {
            $query->where('contact_type', $filters['contact_type'])
                  ->where('contact_id', $filters['contact_id']);
        }

        return $query->get();
    }

    public function loadAggregate(string $id): ?Payment
    {
        return Payment::with(['allocations', 'business', 'currency', 'paymentMethod', 'branch', 'postedBy', 'reversedBy'])->find($id);
    }
}
