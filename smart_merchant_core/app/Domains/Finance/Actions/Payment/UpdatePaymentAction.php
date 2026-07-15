<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use Illuminate\Support\Facades\DB;
use Exception;
use InvalidArgumentException;

class UpdatePaymentAction
{
    private PaymentRepositoryInterface $repository;

    public function __construct(PaymentRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): Payment
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                $payment = $this->repository->findById($id);

                if (!$payment) {
                    throw new Exception("Payment not found.");
                }

                if ($payment->status !== 'Draft') {
                    throw new InvalidArgumentException("Only Draft payments can be updated.");
                }

                return $this->repository->update($id, $data);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
