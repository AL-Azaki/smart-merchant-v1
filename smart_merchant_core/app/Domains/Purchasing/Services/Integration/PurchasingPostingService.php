<?php

namespace App\Domains\Purchasing\Services\Integration;

use App\Domains\Purchasing\Models\PurchaseInvoice;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use Exception;
use Illuminate\Support\Facades\DB;

class PurchasingPostingService
{
    public function __construct(
        private PurchasingPostingRequestDTOBuilder $builder,
        private PostingEngineInterface $postingEngine
    ) {}

    public function postInvoice(PurchaseInvoice $invoice): void
    {
        if ($invoice->status !== 'Posted') {
            throw new Exception("Cannot post an invoice that is not Posted.");
        }

        $requestDTO = $this->builder->build($invoice);

        DB::transaction(function () use ($requestDTO) {
            $this->postingEngine->post($requestDTO);
        });
    }
}
