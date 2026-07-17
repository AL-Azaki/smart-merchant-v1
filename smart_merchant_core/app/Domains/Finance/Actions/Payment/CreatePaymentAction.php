<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Events\Payment\PaymentCreated;
use Illuminate\Support\Facades\DB;
use Exception;

class CreatePaymentAction
{
    private PaymentRepositoryInterface $repository;

    public function __construct(PaymentRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): Payment
    {
        try {
            $payment = DB::transaction(function () use ($data) {
                // Application logic coordinates. Domain logic should be inside Domain Services.
                // The repository handles basic persistence and allocating child entities.
                $data['status'] = 'Draft';
                return $this->repository->create($data);
            });

            event(new PaymentCreated($payment));

            return $payment;
        } catch (Exception $e) {
            // Error Handling Principle: Catch and rethrow Domain or Application exceptions.
            throw $e;
        }
    }
}
