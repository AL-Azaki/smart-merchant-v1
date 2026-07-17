<?php

namespace App\Domains\AccountsPayable\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\AccountsPayable\Services\Integration\PayablePostingBuilder;
use App\Domains\AccountsPayable\Models\PayableEntry;

class ProcessPayablePostingJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $entryId;

    public function __construct(string $entryId)
    {
        $this->entryId = $entryId;
    }

    public function handle(
        PayablePostingBuilder $builder,
        PostingEngineInterface $postingEngine
    ): void {
        $entry = PayableEntry::find($this->entryId);
        if (! $entry) return;

        $request = $builder->build($entry);
        $postingEngine->post($request);
    }
}
