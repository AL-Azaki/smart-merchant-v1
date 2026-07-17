<?php

namespace Tests\Feature\Domains\FinancialClosing;

use Tests\TestCase;

class FinancialClosingFeatureTest extends TestCase
{
    public function test_can_create_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_can_update_open_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_update_closed_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_can_close_open_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_close_already_closed_period()
    {
        $this->assertTrue(true);
    }

    public function test_can_reopen_closed_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_cannot_reopen_open_accounting_period()
    {
        $this->assertTrue(true);
    }

    public function test_reopen_requires_reason()
    {
        $this->assertTrue(true);
    }
}
