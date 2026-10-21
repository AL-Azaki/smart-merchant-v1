'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { useAdminAuth } from '@/lib/admin-context';
import { adminApi } from '@/lib/admin-api';
import type { AdminBusiness } from '@/lib/admin-types';

export default function AdminBusinessesPage() {
  const { lang, t } = useAdminAuth();
  const [businesses, setBusinesses] = useState<AdminBusiness[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const isAr = lang === 'ar';

  useEffect(() => {
    let ignore = false;
    adminApi.getBusinesses()
      .then((res) => {
        if (!ignore) {
          setBusinesses(res.data);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (!ignore) {
          setError(err instanceof Error ? err.message : t.errorBusinessesFetch);
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
    };
  }, [t.errorBusinessesFetch]);

  const handleToggleStatus = async (biz: AdminBusiness) => {
    setUpdatingId(biz.id);
    setError(null);
    setSuccessMsg(null);

    const nextStatus = biz.status === 'Active' ? 'Suspended' : 'Active';
    try {
      const updated = await adminApi.updateBusinessStatus(biz.id, nextStatus);
      setBusinesses((prev) =>
        prev.map((b) => (b.id === updated.id ? { ...b, ...updated } : b))
      );
      setSuccessMsg(t.successBusinessStatus(updated.business_name, updated.status));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t.errorBusinessUpdate);
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <AdminLayout title={t.businessesTitle}>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-extrabold text-[#14233B] dark:text-[#E5EAF2]">
              {t.businessesHeader}
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              {t.businessesSubtitle}
            </p>
          </div>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 text-xs">
            {error}
          </div>
        )}
        {successMsg && (
          <div className="p-3.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 text-xs">
            {successMsg}
          </div>
        )}

        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-xs overflow-hidden transition-colors duration-200">
          {loading ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.loading}
            </div>
          ) : businesses.length === 0 ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.noData}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className={`w-full ${isAr ? 'text-right' : 'text-left'} text-xs`}>
                <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 border-b border-[#E2E8F0] dark:border-[#1E293B] font-bold uppercase tracking-wider text-[11px]">
                  <tr>
                    <th className="py-3 px-4">{t.colBusinessName}</th>
                    <th className="py-3 px-4">{t.colBusinessType}</th>
                    <th className="py-3 px-4">{t.colStorefrontUrl}</th>
                    <th className="py-3 px-4">{t.colPhone}</th>
                    <th className="py-3 px-4">{t.colStatus}</th>
                    <th className="py-3 px-4 text-center">{t.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium text-slate-700 dark:text-slate-300">
                  {businesses.map((biz) => (
                    <tr key={biz.id} className="hover:bg-slate-50/70 dark:hover:bg-slate-850/40 transition">
                      <td className="py-3.5 px-4 font-bold text-[#14233B] dark:text-[#E5EAF2]">
                        {biz.business_name}
                      </td>
                      <td className="py-3.5 px-4">{biz.business_type || 'Retail'}</td>
                      <td className="py-3.5 px-4">
                        {biz.storefront_slug ? (
                          <Link
                            href={`/store/${biz.storefront_slug}`}
                            target="_blank"
                            className="text-[#1E3557] dark:text-[#B3945B] hover:underline flex items-center gap-1 font-mono text-[11px]"
                          >
                            <span>/store/{biz.storefront_slug}</span>
                            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                            </svg>
                          </Link>
                        ) : (
                          <span className="text-slate-400">-</span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-slate-500">{biz.primary_phone || '-'}</td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold border ${
                            biz.status === 'Active'
                              ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800'
                              : 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 border-amber-200 dark:border-amber-800'
                          }`}
                        >
                          {biz.status === 'Active' ? t.statusBusinessActive : t.statusBusinessSuspended}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <button
                          disabled={updatingId === biz.id}
                          onClick={() => handleToggleStatus(biz)}
                          className={`px-3 py-1 rounded-lg text-[11px] font-semibold text-white transition disabled:opacity-50 ${
                            biz.status === 'Active'
                              ? 'bg-amber-600 hover:bg-amber-500'
                              : 'bg-emerald-600 hover:bg-emerald-500'
                          }`}
                        >
                          {updatingId === biz.id
                            ? t.processing
                            : biz.status === 'Active'
                            ? t.btnSuspend
                            : t.btnActivate}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
