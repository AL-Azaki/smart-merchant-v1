<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use InvalidArgumentException;

class DeletePaymentAction
{
    private PaymentRepositoryInterface $repository;

    public function __construct(PaymentRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): bool
    {
        try {
            return DB::transaction(function () use ($id) {
                $payment = $this->repository->findById($id);

                if (!$payment) {
                    throw new Exception("Payment not found.");
                }

                if ($payment->status !== 'Draft') {
                    throw new InvalidArgumentException("Only Draft payments can be deleted.");
                }

                return $this->repository->delete($id);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
