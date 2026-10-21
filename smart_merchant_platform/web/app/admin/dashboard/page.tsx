'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { MetricCard } from '@/components/admin/MetricCard';
import { useAdminAuth } from '@/lib/admin-context';
import { adminApi } from '@/lib/admin-api';
import type { DashboardMetrics } from '@/lib/admin-types';

export default function AdminDashboardPage() {
  const { user, lang, t } = useAdminAuth();
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const handleRetry = () => {
    setLoading(true);
    setError(null);
    adminApi.getDashboard()
      .then((data) => {
        setMetrics(data);
        setLoading(false);
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : t.errorAccountsFetch);
        setLoading(false);
      });
  };

  useEffect(() => {
    let ignore = false;
    adminApi.getDashboard()
      .then((data) => {
        if (!ignore) {
          setMetrics(data);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (!ignore) {
          setError(err instanceof Error ? err.message : t.errorAccountsFetch);
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
    };
  }, [t.errorAccountsFetch]);

  const isAr = lang === 'ar';

  const todayFormatted = new Intl.DateTimeFormat(isAr ? 'ar-SA' : 'en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date());

  return (
    <AdminLayout title={t.dashboardTitle}>
      <div className="space-y-6">
        {/* Welcome Banner inspired by reference screenshot */}
        <div className="relative overflow-hidden rounded-3xl bg-[#14233B] text-white p-6 sm:p-8 shadow-lg border border-[#B3945B]/20">
          <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
                {t.greetingPrefix} {user?.full_name || t.defaultAdminRole}
              </h2>
              <div className="flex items-center gap-2 mt-2 text-xs sm:text-sm text-slate-300">
                <svg className="w-4 h-4 text-[#B3945B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span>{todayFormatted}</span>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Link
                href="/admin/accounts"
                className="px-4 py-2.5 rounded-xl bg-[#1E3557] hover:bg-[#14233B] border border-[#B3945B]/50 text-white font-semibold text-xs sm:text-sm shadow-md transition flex items-center gap-2"
              >
                <svg className="w-4 h-4 text-[#B3945B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span>{t.reviewAccountsBtn}</span>
              </Link>
            </div>
          </div>
        </div>

        {error && (
          <div className="p-4 rounded-2xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 text-xs flex items-center justify-between">
            <span>{error}</span>
            <button
              onClick={handleRetry}
              className="px-3 py-1 bg-red-600 text-white rounded-lg text-xs font-semibold hover:bg-red-700 transition"
            >
              {t.retry}
            </button>
          </div>
        )}

        {/* Metric Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          <MetricCard
            tag={t.metricBusinessesTag}
            tagColor="blue"
            value={loading ? '...' : (metrics?.total_businesses ?? 0)}
            label={t.metricBusinessesLabel}
            icon={
              <svg className="w-5 h-5 text-[#1E3557] dark:text-[#B3945B]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            }
          />

          <MetricCard
            tag={t.metricUsersTag}
            tagColor="purple"
            value={loading ? '...' : (metrics?.total_users ?? 0)}
            label={t.metricUsersLabel}
            icon={
              <svg className="w-5 h-5 text-purple-600 dark:text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            }
          />

          <MetricCard
            tag={t.metricOrdersTag}
            tagColor="emerald"
            value={loading ? '...' : (metrics?.total_orders ?? 0)}
            label={t.metricOrdersLabel}
            icon={
              <svg className="w-5 h-5 text-emerald-600 dark:text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
              </svg>
            }
          />

          <MetricCard
            tag={t.metricDevicesTag}
            tagColor="gold"
            value={loading ? '...' : (metrics?.total_devices ?? 0)}
            label={t.metricDevicesLabel}
            icon={
              <svg className="w-5 h-5 text-[#8C6D33] dark:text-[#D1B57A]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            }
          />
        </div>

        {/* Secondary Account Status Overview Card */}
        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-3xl p-6 shadow-xs transition-colors duration-200">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-[#14233B] dark:text-[#E5EAF2]">
                {t.accountsOverviewTitle}
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {t.accountsOverviewSubtitle}
              </p>
            </div>
            <Link
              href="/admin/accounts"
              className="text-xs font-semibold text-[#1E3557] dark:text-[#B3945B] hover:underline flex items-center gap-1"
            >
              <span>{t.viewAllAccounts}</span>
              <span>{isAr ? '←' : '→'}</span>
            </Link>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-4">
            <div className="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-800">
              <span className="text-[11px] font-medium text-slate-500 dark:text-slate-400">{t.statTotalAccounts}</span>
              <div className="text-xl font-bold text-[#14233B] dark:text-white mt-1">{metrics?.accounts?.total ?? '-'}</div>
            </div>

            <div className="p-4 rounded-2xl bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-900/40">
              <span className="text-[11px] font-medium text-emerald-700 dark:text-emerald-400">{t.statActiveAccounts}</span>
              <div className="text-xl font-bold text-emerald-800 dark:text-emerald-300 mt-1">{metrics?.accounts?.active ?? '-'}</div>
            </div>

            <div className="p-4 rounded-2xl bg-amber-50/50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-900/40">
              <span className="text-[11px] font-medium text-amber-700 dark:text-amber-400">{t.statSuspendedAccounts}</span>
              <div className="text-xl font-bold text-amber-800 dark:text-amber-300 mt-1">{metrics?.accounts?.suspended ?? '-'}</div>
            </div>

            <div className="p-4 rounded-2xl bg-slate-100/60 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
              <span className="text-[11px] font-medium text-slate-600 dark:text-slate-400">{t.statClosedAccounts}</span>
              <div className="text-xl font-bold text-slate-700 dark:text-slate-300 mt-1">{metrics?.accounts?.closed ?? '-'}</div>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}
