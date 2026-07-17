<?php

namespace App\Domains\GeneralLedger\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Actions\CreateJournalEntryAction;
use App\Domains\GeneralLedger\Actions\UpdateJournalEntryAction;
use App\Domains\GeneralLedger\Actions\PostJournalEntryAction;
use App\Domains\GeneralLedger\Actions\ReverseJournalEntryAction;
use App\Domains\GeneralLedger\Actions\ListJournalEntriesAction;
use App\Domains\GeneralLedger\Actions\LoadJournalEntryAggregateAction;
use App\Domains\GeneralLedger\Http\Requests\CreateJournalEntryRequest;
use App\Domains\GeneralLedger\Http\Requests\UpdateJournalEntryRequest;
use App\Domains\GeneralLedger\Http\Requests\PostJournalEntryRequest;
use App\Domains\GeneralLedger\Http\Requests\ReverseJournalEntryRequest;
use App\Domains\GeneralLedger\Http\Resources\JournalEntryResource;
use App\Domains\GeneralLedger\Http\Resources\JournalEntryCollection;
use Illuminate\Http\Request;

class JournalEntryController extends Controller
{
    public function index(Request $request, ListJournalEntriesAction $action)
    {
        $this->authorize('viewAny', JournalEntry::class);
        $entries = $action->execute($request->all());
        return new JournalEntryCollection($entries);
    }

    public function show(JournalEntry $journalEntry, LoadJournalEntryAggregateAction $action)
    {
        $this->authorize('view', $journalEntry);
        $aggregate = $action->execute($journalEntry->id);
        return new JournalEntryResource($aggregate);
    }

    public function store(CreateJournalEntryRequest $request, CreateJournalEntryAction $action)
    {
        $this->authorize('create', JournalEntry::class);
        $entry = $action->execute($request->validated());
        return new JournalEntryResource($entry);
    }

    public function update(UpdateJournalEntryRequest $request, JournalEntry $journalEntry, UpdateJournalEntryAction $action)
    {
        $this->authorize('update', $journalEntry);
        $entry = $action->execute($journalEntry->id, $request->validated());
        return new JournalEntryResource($entry);
    }

    public function post(PostJournalEntryRequest $request, JournalEntry $journalEntry, PostJournalEntryAction $action)
    {
        $this->authorize('post', $journalEntry);
        $entry = $action->execute($journalEntry->id, $request->validated()['user_id']);
        return new JournalEntryResource($entry);
    }

    public function reverse(ReverseJournalEntryRequest $request, JournalEntry $journalEntry, ReverseJournalEntryAction $action)
    {
        $this->authorize('reverse', $journalEntry);
        $entry = $action->execute($journalEntry->id, $request->validated()['user_id'], $request->validated());
        return new JournalEntryResource($entry);
    }
}
