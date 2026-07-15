<?php

namespace Tests\Unit\Domains\Core\Currency;

use Tests\TestCase;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\DTOs\CurrencyDTO;
use App\Domains\Core\Actions\Currency\CreateCurrencyAction;
use App\Domains\Core\Actions\Currency\DeleteCurrencyAction;
use App\Domains\Core\Repositories\Eloquent\CurrencyEloquentRepository;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;

class CurrencyActionsTest extends TestCase
{
    use RefreshDatabase;

    private CurrencyEloquentRepository $repository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = new CurrencyEloquentRepository();
    }

    public function test_it_can_create_currency()
    {
        $dto = new CurrencyDTO(
            currencyCode: 'USD',
            currencyName: 'US Dollar',
            symbol: '$',
            exchangeRate: 1.0,
            isDefault: true,
            isActive: true
        );

        $action = new CreateCurrencyAction($this->repository);
        $currency = $action->execute($dto);

        $this->assertInstanceOf(Currency::class, $currency);
        $this->assertEquals('USD', $currency->currency_code);
        $this->assertTrue($currency->is_default);
    }

    public function test_it_cannot_delete_default_currency()
    {
        $currency = Currency::factory()->create(['is_default' => true]);
        
        $action = new DeleteCurrencyAction($this->repository);
        
        $this->expectException(ValidationException::class);
        $action->execute($currency);
    }
}
