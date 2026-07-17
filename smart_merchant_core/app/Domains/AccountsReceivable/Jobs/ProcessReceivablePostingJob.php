<?php

namespace App\Domains\AccountsReceivable\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\AccountsReceivable\Services\Integration\ReceivablePostingBuilder;
use App\Domains\AccountsReceivable\Models\ReceivableEntry;

class ProcessReceivablePostingJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public string $entryId;

    public function __construct(string $entryId)
    {
        $this->entryId = $entryId;
    }

    public function handle(
        ReceivablePostingBuilder $builder,
        PostingEngineInterface $postingEngine
    ): void {
        $entry = ReceivableEntry::find($this->entryId);
        if (! $entry) return;

        // Skip posting if not required by type, though typically handled in engine
        $request = $builder->build($entry);
        $postingEngine->post($request);
    }
}
