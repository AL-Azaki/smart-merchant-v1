'use client';

import React, { useEffect, useState } from 'react';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { MetricCard } from '@/components/admin/MetricCard';
import { useAdminAuth } from '@/lib/admin-context';
import { adminApi } from '@/lib/admin-api';
import type { AdminSubscription, SubscriptionMetrics } from '@/lib/admin-types';
import { AccountStatementModal } from '@/components/admin/AccountStatementModal';

export default function AdminSubscriptionsPage() {
  const { lang } = useAdminAuth();
  const isAr = lang === 'ar';

  const [subscriptions, setSubscriptions] = useState<AdminSubscription[]>([]);
  const [metrics, setMetrics] = useState<SubscriptionMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);

  // Statement Modal State
  const [statementAccountId, setStatementAccountId] = useState<string | null>(null);

  const fetchSubscriptions = (page = 1) => {
    setLoading(true);
    setError(null);
    adminApi.getSubscriptions({
      page,
      status: statusFilter,
      search: search.trim() || undefined,
    })
      .then((res) => {
        setSubscriptions(res.subscriptions.data);
        setMetrics(res.metrics);
        setCurrentPage(res.subscriptions.current_page);
        setLastPage(res.subscriptions.last_page);
        setLoading(false);
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : (isAr ? 'فشل تحميل الاشتراكات' : 'Failed to load subscriptions'));
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchSubscriptions(1);
  }, [statusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchSubscriptions(1);
  };

  const statusTabs = [
    { key: 'All', label: isAr ? 'الكل' : 'All' },
    { key: 'Active', label: isAr ? 'نشط' : 'Active' },
    { key: 'Expired', label: isAr ? 'منتهي' : 'Expired' },
    { key: 'Suspended', label: isAr ? 'معلق' : 'Suspended' },
  ];

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'Active':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            {isAr ? 'نشط' : 'Active'}
          </span>
        );
      case 'Expired':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-red-100 text-red-800 dark:bg-red-950/60 dark:text-red-300">
            <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
            {isAr ? 'منتهي' : 'Expired'}
          </span>
        );
      case 'Suspended':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
            {isAr ? 'معلق' : 'Suspended'}
          </span>
        );
      default:
        return (
          <span className="px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300">
            {status}
          </span>
        );
    }
  };

  const formatFrequency = (freq: string) => {
    switch (freq) {
      case 'Monthly': return isAr ? 'شهرياً' : 'Monthly';
      case 'Every2Months': return isAr ? 'كل شهرين' : 'Every 2 Months';
      case 'Every3Months': return isAr ? 'كل 3 أشهر (ربع سنوي)' : 'Every 3 Months';
      case 'Every4Months': return isAr ? 'كل 4 أشهر' : 'Every 4 Months';
      case 'SemiAnnual': return isAr ? 'نصف سنوي (كل 6 أشهر)' : 'Semi-Annual';
      case 'Yearly': return isAr ? 'سنوياً' : 'Yearly';
      case 'SinglePayment': return isAr ? 'دفعة واحدة' : 'Single Payment';
      default: return freq;
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-xl sm:text-2xl font-black text-[#14233B] dark:text-[#E5EAF2] tracking-tight">
              {isAr ? 'إدارة الاشتراكات والأقساط' : 'Subscriptions & Installment Management'}
            </h1>
            <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
              {isAr
                ? 'متابعة عقود التجار، جداول استحقاق الأقساط، كشوفات الحساب، وتمديد رخص التشغيل.'
                : 'Monitor merchant contracts, installment due schedules, account statements, and lease renewals.'}
            </p>
          </div>
        </div>

        {/* KPI Metrics */}
        {metrics && (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <MetricCard
              label={isAr ? 'إجمالي العقود' : 'Total Contracts'}
              value={metrics.total_subscriptions}
              icon={
                <svg className="w-6 h-6 text-[#B3945B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              }
              tag={isAr ? `${metrics.active_subscriptions} نشط` : `${metrics.active_subscriptions} Active`}
              tagColor="emerald"
            />

            <MetricCard
              label={isAr ? 'الإيرادات المحصلة' : 'Revenue Collected'}
              value={`${Math.round(metrics.total_revenue).toLocaleString()} YER`}
              icon={
                <svg className="w-6 h-6 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              }
              tag={isAr ? `من إجمالي ${Math.round(metrics.total_contracted).toLocaleString()}` : `Total ${Math.round(metrics.total_contracted).toLocaleString()}`}
              tagColor="blue"
            />

            <MetricCard
              label={isAr ? 'أقساط قيد الانتظار' : 'Pending Installments'}
              value={metrics.pending_installments_count}
              icon={
                <svg className="w-6 h-6 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              }
              tag={isAr ? 'بانتظار السداد' : 'Awaiting Pay'}
              tagColor="amber"
            />

            <MetricCard
              label={isAr ? 'أقساط متأخرة' : 'Overdue Installments'}
              value={metrics.overdue_installments_count}
              icon={
                <svg className="w-6 h-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              }
              tag={isAr ? 'تحتاج متابعة فورية' : 'Requires Followup'}
              tagColor="rose"
            />
          </div>
        )}

        {/* Filters & Search */}
        <div className="flex flex-col sm:flex-row gap-3 items-stretch sm:items-center justify-between">
          {/* Status Tabs */}
          <div className="inline-flex p-1 bg-slate-100 dark:bg-slate-800/60 rounded-xl text-xs font-semibold">
            {statusTabs.map((tab) => (
              <button
                key={tab.key}
                type="button"
                onClick={() => setStatusFilter(tab.key)}
                className={`px-3 py-1.5 rounded-lg transition ${
                  statusFilter === tab.key
                    ? 'bg-white dark:bg-[#111C2F] text-[#14233B] dark:text-[#E5EAF2] shadow-xs'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Search Form */}
          <form onSubmit={handleSearchSubmit} className="flex gap-2">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={isAr ? 'بحث بالتاجر، المتجر، الإيميل...' : 'Search merchant, business, email...'}
              className="w-full sm:w-72 px-4 py-2 text-xs bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
            />
            <button
              type="submit"
              className="px-4 py-2 bg-[#14233B] hover:bg-[#1E3557] text-white rounded-xl text-xs font-bold transition border border-[#B3945B]/30"
            >
              {isAr ? 'بحث' : 'Search'}
            </button>
          </form>
        </div>

        {error && (
          <div className="p-3.5 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-300 text-xs rounded-xl">
            {error}
          </div>
        )}

        {/* Subscriptions Table */}
        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-xs overflow-hidden">
          {loading ? (
            <div className="py-16 text-center text-xs text-slate-400">
              <div className="w-6 h-6 border-2 border-[#B3945B] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
              <span>{isAr ? 'جاري تحميل سجل الاشتراكات...' : 'Loading subscriptions...'}</span>
            </div>
          ) : subscriptions.length === 0 ? (
            <div className="py-16 text-center text-xs text-slate-400">
              {isAr ? 'لا توجد اشتراكات تطابق البحث الحالي.' : 'No subscriptions matching current criteria.'}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className={`w-full ${isAr ? 'text-right' : 'text-left'} text-xs`}>
                <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 border-b border-[#E2E8F0] dark:border-[#1E293B] font-bold text-[11px] uppercase">
                  <tr>
                    <th className="py-3 px-4">{isAr ? 'التاجر / المنشأة' : 'Merchant / Account'}</th>
                    <th className="py-3 px-4">{isAr ? 'الخطة' : 'Plan'}</th>
                    <th className="py-3 px-4">{isAr ? 'دورة السداد' : 'Frequency'}</th>
                    <th className="py-3 px-4">{isAr ? 'إجمالي العقد' : 'Total Contract'}</th>
                    <th className="py-3 px-4">{isAr ? 'نسبة السداد' : 'Paid Progress'}</th>
                    <th className="py-3 px-4">{isAr ? 'الحالة' : 'Status'}</th>
                    <th className="py-3 px-4">{isAr ? 'نهاية القسط الحالي' : 'Lease Expiry'}</th>
                    <th className="py-3 px-4 text-center">{isAr ? 'كشف الحساب' : 'Statement'}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                  {subscriptions.map((sub) => {
                    const total = Number(sub.total_amount) || 1;
                    const paid = Number(sub.amount_paid) || 0;
                    const percent = Math.min(100, Math.round((paid / total) * 100));

                    return (
                      <tr key={sub.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition">
                        <td className="py-3.5 px-4">
                          <div className="font-bold text-slate-900 dark:text-white">
                            {sub.account?.name || '—'}
                          </div>
                          <div className="text-[11px] text-slate-400">
                            {sub.account?.owner_name} • {sub.account?.email}
                          </div>
                        </td>

                        <td className="py-3.5 px-4 font-semibold text-slate-800 dark:text-slate-200">
                          {sub.plan?.plan_name || 'Enterprise'}
                        </td>

                        <td className="py-3.5 px-4 text-slate-600 dark:text-slate-400">
                          {formatFrequency(sub.installment_frequency)}
                        </td>

                        <td className="py-3.5 px-4 font-bold text-slate-900 dark:text-white">
                          {Number(sub.total_amount).toLocaleString()} YER
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="w-32 space-y-1">
                            <div className="flex justify-between text-[10px] text-slate-500">
                              <span>{paid.toLocaleString()} YER</span>
                              <span>{percent}%</span>
                            </div>
                            <div className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                              <div
                                className={`h-full rounded-full transition-all duration-500 ${
                                  percent === 100 ? 'bg-emerald-500' : percent > 50 ? 'bg-sky-500' : 'bg-[#B3945B]'
                                }`}
                                style={{ width: `${percent}%` }}
                              />
                            </div>
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          {getStatusBadge(sub.status)}
                        </td>

                        <td className="py-3.5 px-4 text-slate-600 dark:text-slate-400 text-[11px]">
                          {sub.offline_lease_valid_until
                            ? String(sub.offline_lease_valid_until).split('T')[0]
                            : (sub.end_date ? String(sub.end_date).split('T')[0] : '—')}
                        </td>

                        <td className="py-3.5 px-4 text-center">
                          <button
                            type="button"
                            onClick={() => setStatementAccountId(sub.account_id)}
                            className="px-3 py-1.5 rounded-xl text-xs font-bold bg-[#14233B] text-[#B3945B] hover:bg-[#1E3557] hover:text-white border border-[#B3945B]/30 transition shadow-xs flex items-center gap-1.5 mx-auto"
                          >
                            <span>📋</span>
                            <span>{isAr ? 'كشف الحساب' : 'Statement'}</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {lastPage > 1 && (
            <div className="flex items-center justify-between px-4 py-3 bg-slate-50 dark:bg-slate-800/40 border-t border-[#E2E8F0] dark:border-[#1E293B] text-xs">
              <span className="text-slate-500 dark:text-slate-400">
                {isAr ? `صفحة ${currentPage} من ${lastPage}` : `Page ${currentPage} of ${lastPage}`}
              </span>
              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={currentPage <= 1 || loading}
                  onClick={() => fetchSubscriptions(currentPage - 1)}
                  className="px-3 py-1 rounded-lg bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] text-slate-700 dark:text-slate-300 disabled:opacity-50 hover:bg-slate-50 transition"
                >
                  {isAr ? 'السابق' : 'Previous'}
                </button>
                <button
                  type="button"
                  disabled={currentPage >= lastPage || loading}
                  onClick={() => fetchSubscriptions(currentPage + 1)}
                  className="px-3 py-1 rounded-lg bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] text-slate-700 dark:text-slate-300 disabled:opacity-50 hover:bg-slate-50 transition"
                >
                  {isAr ? 'التالي' : 'Next'}
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Account Statement & Payments Modal */}
        <AccountStatementModal
          isOpen={!!statementAccountId}
          accountId={statementAccountId}
          onClose={() => setStatementAccountId(null)}
          onPaymentSuccess={() => fetchSubscriptions(currentPage)}
        />
      </div>
    </AdminLayout>
  );
}
