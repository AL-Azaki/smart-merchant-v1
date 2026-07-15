<?php

namespace Tests\Unit\Domains\Finance\Actions\ManualJournal;

use App\Domains\Finance\Actions\ManualJournal\CreateManualJournalAction;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\ManualJournal\CreateManualJournalDTO;
use App\Domains\Finance\DTOs\ManualJournal\CreateManualJournalLineDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use PHPUnit\Framework\TestCase;

class CreateManualJournalActionTest extends TestCase
{
    public function test_it_creates_manual_journal_successfully()
    {
        $postingEngineMock = $this->createMock(PostingEngineInterface::class);
        
        $expectedResult = new PostingResultDTO('journal-123', 'JE-1000', 'Posted', '2026-07-14');
        
        $postingEngineMock->expects($this->once())
            ->method('post')
            ->willReturn($expectedResult);

        $action = new CreateManualJournalAction($postingEngineMock);

        $line1 = new CreateManualJournalLineDTO('acc-1', 'Debit', 100, 100);
        $line2 = new CreateManualJournalLineDTO('acc-2', 'Credit', 100, 100);

        $dto = new CreateManualJournalDTO(
            'bus-1', 'fp-1', '2026-07-14', '2026-07-14', 'curr-1', 1.0, 'Test Journal', 'user-1', [$line1, $line2]
        );

        $result = $action->execute($dto);

        $this->assertEquals('journal-123', $result->journalEntryId);
        $this->assertEquals('JE-1000', $result->journalNumber);
        $this->assertEquals('Posted', $result->status);
    }
}
