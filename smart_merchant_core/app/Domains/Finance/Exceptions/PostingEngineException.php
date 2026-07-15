<?php

namespace App\Domains\Finance\Exceptions;

use Exception;

class PostingEngineException extends Exception
{
    public static function invalidFiscalPeriod(): self
    {
        return new self('Fiscal period is not open, belongs to another business, or does not encompass the posting date.');
    }

    public static function unbalancedJournal(): self
    {
        return new self('Journal entry is not balanced. Debit and Credit base amounts must be equal.');
    }

    public static function inactiveOrInvalidAccount(string $accountId): self
    {
        return new self("Account [{$accountId}] is inactive, not a posting account, or does not belong to the business.");
    }

    public static function invalidCurrencyOrExchangeRate(): self
    {
        return new self('All journal lines must share the exact same currency and exchange rate as the journal header.');
    }

    public static function invalidAmounts(): self
    {
        return new self('Journal line amounts must be strictly greater than zero.');
    }

    public static function idempotencyViolation(string $docType, string $docId): self
    {
        return new self("A posted journal already exists for document type [{$docType}] with ID [{$docId}].");
    }

    public static function invalidDocumentType(string $docType): self
    {
        return new self("Document type [{$docType}] is not supported in V1.");
    }

    public static function reverseDraftNotAllowed(): self
    {
        return new self('Cannot reverse a journal entry that is in Draft status.');
    }

    public static function reverseAlreadyReversed(): self
    {
        return new self('Cannot reverse a journal entry that has already been reversed.');
    }

    public static function missingLines(): self
    {
        return new self('Journal entry must have at least two lines.');
    }

    public static function invalidType(string $type): self
    {
        return new self("Journal line type [{$type}] is invalid. Must be Debit or Credit.");
    }
}
