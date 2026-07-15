<?php

namespace Tests\Unit\Domains\Finance\Actions\ManualJournal;

use App\Domains\Finance\Actions\ManualJournal\ReverseManualJournalAction;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\ManualJournal\ReverseManualJournalDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use PHPUnit\Framework\TestCase;

class ReverseManualJournalActionTest extends TestCase
{
    public function test_it_reverses_manual_journal_successfully()
    {
        $postingEngineMock = $this->createMock(PostingEngineInterface::class);
        
        $expectedResult = new PostingResultDTO('journal-124', 'JE-1001', 'Posted', '2026-07-15');
        
        $postingEngineMock->expects($this->once())
            ->method('reverse')
            ->willReturn($expectedResult);

        $action = new ReverseManualJournalAction($postingEngineMock);

        $dto = new ReverseManualJournalDTO('journal-123', '2026-07-15', 'user-1', 'Reversal test');

        $result = $action->execute($dto);

        $this->assertEquals('journal-124', $result->journalEntryId);
        $this->assertEquals('JE-1001', $result->journalNumber);
        $this->assertEquals('Posted', $result->status);
    }
}
