<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Repositories\Contracts\FiscalYearRepositoryInterface;
use Carbon\Carbon;

class CreateFiscalYearAction
{
    public function __construct(private readonly FiscalYearRepositoryInterface $repository) {}

    public function handle(string $businessId): FiscalYear
    {
        $yearName = date('Y');
        $startDate = Carbon::createFromDate(date('Y'), 1, 1)->startOfDay();
        $endDate = Carbon::createFromDate(date('Y'), 12, 31)->endOfDay();
        
        $fiscalYear = $this->repository->create([
            'business_id' => $businessId,
            'fiscal_year_code' => 'FY-' . $yearName,
            'fiscal_year_name' => 'Fiscal Year ' . $yearName,
            'start_date'  => $startDate->toDateString(),
            'end_date'    => $endDate->toDateString(),
            'status'   => 'Open',
        ]);

        $periods = [];
        for ($month = 1; $month <= 12; $month++) {
            $periodStart = Carbon::createFromDate(date('Y'), $month, 1)->startOfDay();
            $periodEnd = $periodStart->copy()->endOfMonth()->endOfDay();
            
            $periods[] = [
                'period_number' => $month,
                'period_name' => date('F Y', mktime(0, 0, 0, $month, 1, date('Y'))),
                'start_date'  => $periodStart->toDateString(),
                'end_date'    => $periodEnd->toDateString(),
                'status'   => 'Open',
            ];
        }

        $this->repository->createPeriods($fiscalYear->id, $businessId, $periods);

        return $fiscalYear;
    }
}
