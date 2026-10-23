<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Business;
use App\Models\Currency;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\SubscriptionInstallment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SubscriptionInstallmentTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private Currency $currency;
    private Plan $plan;

    protected function setUp(): void
    {
        parent::setUp();

        $this->currency = Currency::create([
            'currency_code' => 'YER',
            'currency_name_ar' => 'ريال يمني',
            'currency_name_en' => 'Yemeni Rial',
            'currency_symbol' => '﷼',
            'decimal_places' => 2,
            'exchange_rate' => 1.0,
            'is_base_currency' => true,
            'is_active' => true,
        ]);

        $this->plan = Plan::create([
            'plan_name' => 'خطة رواد الأعمال (Entrepreneur)',
            'currency_id' => $this->currency->id,
            'billing_cycle' => 'Yearly',
            'duration_months' => 12,
            'price' => 120000.00,
            'is_active' => true,
        ]);

        $account = Account::create([
            'name' => 'منصة تاجركم الإدارية',
            'owner_name' => 'المدير العام',
            'email' => 'admin@tajer.com',
            'status' => 'Active',
        ]);

        $this->admin = User::create([
            'account_id' => $account->id,
            'full_name' => 'مدير النظام',
            'username' => 'superadmin',
            'email' => 'admin@tajer.com',
            'password_hash' => bcrypt('password'),
            'is_active' => true,
        ]);

        Sanctum::actingAs($this->admin, ['*']);
    }

    public function test_admin_can_approve_account_with_installment_schedule(): void
    {
        $account = Account::create([
            'name' => 'مؤسسة الأمل التجارية',
            'owner_name' => 'محمد الأمل',
            'email' => 'alamal@test.com',
            'phone' => '777000111',
            'status' => 'Pending',
        ]);

        Business::create([
            'account_id' => $account->id,
            'business_name' => 'الأمل هايبر ماركت',
            'business_type' => 'retail',
            'status' => 'Active',
        ]);

        $response = $this->postJson("/api/admin/v1/accounts/{$account->id}/approve", [
            'plan_id' => $this->plan->id,
            'total_amount' => 120000.00,
            'down_payment' => 30000.00,
            'installment_frequency' => 'Every3Months',
            'installments_count' => 4,
            'max_offline_days' => 14,
            'grace_period_days' => 5,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'Active')
            ->assertJsonPath('subscription.status', 'Active')
            ->assertJsonPath('subscription.total_amount', '120000.00')
            ->assertJsonPath('subscription.amount_paid', '30000.00');

        $this->assertDatabaseHas('accounts', [
            'id' => $account->id,
            'status' => 'Active',
        ]);

        $this->assertDatabaseHas('subscriptions', [
            'account_id' => $account->id,
            'total_amount' => 120000.00,
            'amount_paid' => 30000.00,
            'installment_frequency' => 'Every3Months',
        ]);

        // Down payment + 3 installments = 4 installments
        $installments = SubscriptionInstallment::where('account_id', $account->id)->get();
        $this->assertCount(4, $installments);

        // First installment is down payment (Paid)
        $this->assertEquals('Paid', $installments->first()->status);
        $this->assertEquals(30000.00, (float)$installments->first()->paid_amount);

        // Next installments are Pending
        $this->assertEquals('Pending', $installments->get(1)->status);
    }

    public function test_admin_can_view_all_subscriptions_and_pay_installment(): void
    {
        $account = Account::create([
            'name' => 'مؤسسة الشروق',
            'owner_name' => 'عبدالله الشروق',
            'email' => 'shorooq@test.com',
            'status' => 'Active',
        ]);

        $subscription = Subscription::create([
            'account_id' => $account->id,
            'plan_id' => $this->plan->id,
            'start_date' => now()->toDateString(),
            'end_date' => now()->addYear()->toDateString(),
            'total_amount' => 60000.00,
            'amount_paid' => 0.00,
            'installments_count' => 2,
            'installment_frequency' => 'SemiAnnual',
            'status' => 'Active',
        ]);

        $installment1 = SubscriptionInstallment::create([
            'subscription_id' => $subscription->id,
            'account_id' => $account->id,
            'installment_number' => 1,
            'due_date' => now()->toDateString(),
            'amount' => 30000.00,
            'paid_amount' => 0.00,
            'status' => 'Pending',
        ]);

        $installment2 = SubscriptionInstallment::create([
            'subscription_id' => $subscription->id,
            'account_id' => $account->id,
            'installment_number' => 2,
            'due_date' => now()->addMonths(6)->toDateString(),
            'amount' => 30000.00,
            'paid_amount' => 0.00,
            'status' => 'Pending',
        ]);

        // 1. Get all subscriptions
        $listResponse = $this->getJson('/api/admin/v1/subscriptions');
        $listResponse->assertStatus(200)
            ->assertJsonStructure(['metrics', 'subscriptions']);

        // 2. Pay installment 1
        $payResponse = $this->postJson("/api/admin/v1/subscriptions/{$subscription->id}/installments/{$installment1->id}/pay", [
            'amount' => 30000.00,
            'payment_method' => 'Kuraimi Transfer',
            'reference_number' => 'KM-998877',
            'notes' => 'حوالة عبر بنك الكريمي',
        ]);

        $payResponse->assertStatus(200)
            ->assertJsonPath('installment.status', 'Paid')
            ->assertJsonPath('subscription.amount_paid', '30000.00')
            ->assertJsonStructure(['lease' => ['payload', 'signed_token']]);

        $this->assertDatabaseHas('subscription_installments', [
            'id' => $installment1->id,
            'status' => 'Paid',
            'payment_method' => 'Kuraimi Transfer',
        ]);

        $this->assertDatabaseHas('subscription_payments', [
            'subscription_id' => $subscription->id,
            'amount' => 30000.00,
            'reference_number' => 'KM-998877',
        ]);
    }

    public function test_account_statement_returns_full_financial_ledger(): void
    {
        $account = Account::create([
            'name' => 'شركة النجاح',
            'owner_name' => 'نجاح خالد',
            'email' => 'najah@test.com',
            'status' => 'Active',
        ]);

        $subscription = Subscription::create([
            'account_id' => $account->id,
            'plan_id' => $this->plan->id,
            'start_date' => now()->toDateString(),
            'end_date' => now()->addYear()->toDateString(),
            'total_amount' => 100000.00,
            'amount_paid' => 50000.00,
            'status' => 'Active',
        ]);

        $response = $this->getJson("/api/admin/v1/accounts/{$account->id}/statement");
        $response->assertStatus(200)
            ->assertJsonStructure([
                'account',
                'active_subscription',
                'all_subscriptions',
                'installments',
            ]);
    }
}
