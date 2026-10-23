'use client';

import React, { useEffect, useState } from 'react';
import { AdminLayout } from '@/components/admin/AdminLayout';
import { useAdminAuth } from '@/lib/admin-context';
import { adminApi } from '@/lib/admin-api';
import type { AdminAccount, CreateAccountPayload, CreatedAccountResponse } from '@/lib/admin-types';
import { ApproveSubscriptionModal } from '@/components/admin/ApproveSubscriptionModal';
import { AccountStatementModal } from '@/components/admin/AccountStatementModal';

export default function AdminAccountsPage() {
  const { lang, t } = useAdminAuth();
  const [accounts, setAccounts] = useState<AdminAccount[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const [statusFilter, setStatusFilter] = useState<'All' | 'Pending' | 'Active' | 'Suspended' | 'Closed'>('All');
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);

  // Modal / Confirm state
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    type: 'approve' | 'suspend' | 'reactivate';
    account: AdminAccount | null;
    reason?: string;
  }>({
    open: false,
    type: 'approve',
    account: null,
    reason: '',
  });

  const [actionLoading, setActionLoading] = useState(false);
  const [approveModalAccount, setApproveModalAccount] = useState<AdminAccount | null>(null);
  const [statementAccountId, setStatementAccountId] = useState<string | null>(null);

  // Create Account State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);
  const [createdSuccessData, setCreatedSuccessData] = useState<CreatedAccountResponse['data'] | null>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [formTab, setFormTab] = useState<'user' | 'business'>('user');

  const initialFormState: CreateAccountPayload & { password_confirmation: string } = {
    first_name: '',
    last_name: '',
    username: '',
    email: '',
    phone: '',
    password: '',
    password_confirmation: '',
    business_name: '',
    business_type: 'retail',
    primary_phone: '',
    primary_email: '',
    country: 'اليمن',
    city: 'صنعاء',
    address: '',
    currency: 'YER',
  };

  const [formData, setFormData] = useState(initialFormState);

  const isAr = lang === 'ar';

  const fetchAccounts = (page = 1) => {
    setLoading(true);
    setError(null);
    adminApi.getAccounts({
      page,
      status: statusFilter,
      search: search.trim() || undefined,
    })
      .then((res) => {
        setAccounts(res.data);
        setCurrentPage(res.current_page);
        setLastPage(res.last_page);
        setTotalCount(res.total);
        setLoading(false);
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : t.errorAccountsFetch);
        setLoading(false);
      });
  };

  useEffect(() => {
    let ignore = false;
    adminApi.getAccounts({ page: 1, status: statusFilter, search: search.trim() || undefined })
      .then((res) => {
        if (!ignore) {
          setAccounts(res.data);
          setCurrentPage(res.current_page);
          setLastPage(res.last_page);
          setTotalCount(res.total);
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
  }, [statusFilter, t.errorAccountsFetch]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchAccounts(1);
  };

  const openAction = (account: AdminAccount, type: 'approve' | 'suspend' | 'reactivate') => {
    if (type === 'approve') {
      setApproveModalAccount(account);
      return;
    }
    setConfirmDialog({
      open: true,
      type,
      account,
      reason: '',
    });
  };

  const handleExecuteAction = async () => {
    if (!confirmDialog.account) return;
    setActionLoading(true);
    setError(null);
    setSuccessMsg(null);

    const { type, account, reason } = confirmDialog;

    try {
      let updated: AdminAccount;
      if (type === 'approve') {
        updated = await adminApi.approveAccount(account.id);
        setSuccessMsg(t.successAccountApproved(updated.name));
      } else if (type === 'suspend') {
        updated = await adminApi.suspendAccount(account.id, reason);
        setSuccessMsg(t.successAccountSuspended(updated.name));
      } else {
        updated = await adminApi.reactivateAccount(account.id);
        setSuccessMsg(t.successAccountReactivated(updated.name));
      }

      setAccounts((prev) =>
        prev.map((acc) => (acc.id === updated.id ? { ...acc, ...updated } : acc))
      );

      setConfirmDialog({ open: false, type: 'approve', account: null });
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t.errorAccountAction);
    } finally {
      setActionLoading(false);
    }
  };

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreateError(null);

    // Validation
    if (
      !formData.first_name.trim() ||
      !formData.last_name.trim() ||
      !formData.username.trim() ||
      !formData.email.trim() ||
      !formData.password ||
      !formData.business_name.trim() ||
      !formData.business_type
    ) {
      setCreateError(t.validationRequiredFields);
      return;
    }

    if (formData.password !== formData.password_confirmation) {
      setCreateError(t.validationPasswordMismatch);
      return;
    }

    setCreateLoading(true);

    try {
      const payload: CreateAccountPayload = {
        first_name: formData.first_name.trim(),
        last_name: formData.last_name.trim(),
        username: formData.username.trim(),
        email: formData.email.trim(),
        phone: formData.phone?.trim() || undefined,
        password: formData.password,
        business_name: formData.business_name.trim(),
        business_type: formData.business_type,
        primary_phone: formData.primary_phone?.trim() || undefined,
        primary_email: formData.primary_email?.trim() || undefined,
        country: formData.country?.trim() || undefined,
        city: formData.city?.trim() || undefined,
        address: formData.address?.trim() || undefined,
        currency: formData.currency?.trim() || undefined,
      };

      const res = await adminApi.createAccount(payload);
      setCreatedSuccessData(res.data);
      setAccounts((prev) => [res.data.account, ...prev]);
      setTotalCount((prev) => prev + 1);
      setSuccessMsg(t.successAccountApproved(res.data.account.name));
    } catch (err: unknown) {
      setCreateError(err instanceof Error ? err.message : 'فشل إنشاء الحساب');
    } finally {
      setCreateLoading(false);
    }
  };

  const handleCopy = (text: string, field: string) => {
    if (navigator?.clipboard) {
      navigator.clipboard.writeText(text);
      setCopiedField(field);
      setTimeout(() => setCopiedField(null), 2500);
    }
  };

  const closeCreateModal = () => {
    setShowCreateModal(false);
    setCreatedSuccessData(null);
    setCreateError(null);
    setFormData(initialFormState);
    setFormTab('user');
  };

  const getStatusBadge = (status: AdminAccount['status']) => {
    switch (status) {
      case 'Pending':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300 border border-amber-300 dark:border-amber-700">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
            <span>{t.statusPending}</span>
          </span>
        );
      case 'Active':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
            {t.statusActive}
          </span>
        );
      case 'Suspended':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 border border-amber-200 dark:border-amber-800">
            {t.statusSuspended}
          </span>
        );
      case 'Closed':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 border border-slate-200 dark:border-slate-700">
            {t.statusClosed}
          </span>
        );
      default:
        return <span>{status}</span>;
    }
  };

  const filterTabs = [
    { key: 'All', label: t.statusAll },
    { key: 'Pending', label: t.statusPending },
    { key: 'Active', label: t.statusActive },
    { key: 'Suspended', label: t.statusSuspended },
    { key: 'Closed', label: t.statusClosed },
  ] as const;

  const businessTypes = [
    { id: 'grocery', label: t.typeGrocery },
    { id: 'retail', label: t.typeRetail },
    { id: 'wholesale', label: t.typeWholesale },
    { id: 'restaurant', label: t.typeRestaurant },
    { id: 'cafe', label: t.typeCafe },
    { id: 'pharmacy', label: t.typePharmacy },
    { id: 'electronics', label: t.typeElectronics },
    { id: 'fashion', label: t.typeFashion },
    { id: 'other', label: t.typeOther },
  ];

  return (
    <AdminLayout title={t.accountsTitle}>
      <div className="space-y-6">
        {/* Header Bar */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-extrabold text-[#14233B] dark:text-[#E5EAF2]">
              {t.accountsHeader}
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              {t.totalAccountsCount(totalCount)}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Create Account Action */}
            <button
              type="button"
              onClick={() => {
                setCreatedSuccessData(null);
                setCreateError(null);
                setShowCreateModal(true);
              }}
              className="inline-flex items-center gap-2 px-4 py-2 bg-[#14233B] hover:bg-[#1E3557] text-[#B3945B] hover:text-white border border-[#B3945B]/40 rounded-xl text-xs sm:text-sm font-bold shadow-xs transition"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
              </svg>
              <span>{t.btnCreateAccount}</span>
            </button>

            {/* Status Filter Tabs */}
            <div className="inline-flex p-1 bg-slate-200/60 dark:bg-slate-800 rounded-xl text-xs font-semibold">
              {filterTabs.map((tab) => (
                <button
                  key={tab.key}
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
          </div>
        </div>

        {/* Search Bar */}
        <form onSubmit={handleSearchSubmit} className="flex gap-2">
          <div className="relative flex-1">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t.accountsSearchPlaceholder}
              className="w-full px-4 py-2.5 text-xs sm:text-sm bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
            />
          </div>
          <button
            type="submit"
            className="px-5 py-2.5 bg-[#14233B] hover:bg-[#1E3557] text-white rounded-xl text-xs sm:text-sm font-semibold transition border border-[#B3945B]/30"
          >
            {t.search}
          </button>
        </form>

        {/* Feedback alerts */}
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

        {/* Data Table */}
        <div className="bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-xs overflow-hidden transition-colors duration-200">
          {loading ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.loading}
            </div>
          ) : accounts.length === 0 ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              {t.noData}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className={`w-full ${isAr ? 'text-right' : 'text-left'} text-xs`}>
                <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 border-b border-[#E2E8F0] dark:border-[#1E293B] font-bold uppercase tracking-wider text-[11px]">
                  <tr>
                    <th className="py-3 px-4">{t.colAccountName}</th>
                    <th className="py-3 px-4">{t.colOwnerName}</th>
                    <th className="py-3 px-4">{t.colEmail}</th>
                    <th className="py-3 px-4">{t.colBusinessesCount}</th>
                    <th className="py-3 px-4">{t.colStatus}</th>
                    <th className="py-3 px-4">{t.colCreatedAt}</th>
                    <th className="py-3 px-4 text-center">{t.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                  {accounts.map((acc) => (
                    <tr
                      key={acc.id}
                      className="hover:bg-slate-50/70 dark:hover:bg-slate-800/30 transition-colors"
                    >
                      <td className="py-3.5 px-4 font-bold text-[#14233B] dark:text-[#E5EAF2]">
                        {acc.name}
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 dark:text-slate-300">
                        {acc.owner_name}
                      </td>
                      <td className="py-3.5 px-4 text-slate-500 dark:text-slate-400 font-mono text-[11px]" dir="ltr">
                        {acc.email}
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 dark:text-slate-300">
                        <span className="inline-block px-2 py-0.5 rounded-md bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-semibold text-[11px]">
                          {acc.businesses_count ?? 1}
                        </span>
                      </td>
                      <td className="py-3.5 px-4">{getStatusBadge(acc.status)}</td>
                      <td className="py-3.5 px-4 text-slate-500 dark:text-slate-400 text-[11px]">
                        {new Date(acc.created_at).toLocaleDateString(isAr ? 'ar-EG' : 'en-US')}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <div className="inline-flex items-center gap-1.5">
                          {acc.status === 'Pending' ? (
                            <button
                              onClick={() => openAction(acc, 'approve')}
                              className="px-3 py-1 rounded-lg text-[11px] font-bold bg-emerald-600 hover:bg-emerald-500 text-white shadow-xs transition flex items-center gap-1"
                            >
                              <span>✓</span>
                              <span>{t.btnApproveAndActivate}</span>
                            </button>
                          ) : acc.status !== 'Active' ? (
                            <button
                              onClick={() => openAction(acc, 'approve')}
                              className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 hover:bg-emerald-100 dark:hover:bg-emerald-900/60 border border-emerald-200 dark:border-emerald-800 transition"
                            >
                              {acc.status === 'Suspended' ? t.btnReactivate : t.btnActivate}
                            </button>
                          ) : (
                            <div className="flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => setStatementAccountId(acc.id)}
                                title={isAr ? 'كشف حساب الأقساط والاشتراك' : 'Account Statement'}
                                className="px-2 py-1 rounded-lg text-[11px] font-semibold bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 hover:bg-[#B3945B]/20 hover:text-[#B3945B] border border-slate-200 dark:border-slate-700 transition flex items-center gap-1"
                              >
                                <span>📋</span>
                                <span>{isAr ? 'كشف الحساب' : 'Statement'}</span>
                              </button>
                              <button
                                onClick={() => openAction(acc, 'suspend')}
                                className="px-2.5 py-1 rounded-lg text-[11px] font-semibold bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 hover:bg-amber-100 dark:hover:bg-amber-900/60 border border-amber-200 dark:border-amber-800 transition"
                              >
                                {t.btnSuspend}
                              </button>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {lastPage > 1 && (
            <div className="flex items-center justify-between px-4 py-3 bg-slate-50 dark:bg-slate-800/40 border-t border-[#E2E8F0] dark:border-[#1E293B] text-xs">
              <span className="text-slate-500 dark:text-slate-400">
                {t.pageNumber(currentPage, lastPage)}
              </span>
              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={currentPage <= 1 || loading}
                  onClick={() => fetchAccounts(currentPage - 1)}
                  className="px-3 py-1 rounded-lg bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] text-slate-700 dark:text-slate-300 disabled:opacity-50 hover:bg-slate-50 transition"
                >
                  {t.previous}
                </button>
                <button
                  type="button"
                  disabled={currentPage >= lastPage || loading}
                  onClick={() => fetchAccounts(currentPage + 1)}
                  className="px-3 py-1 rounded-lg bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] text-slate-700 dark:text-slate-300 disabled:opacity-50 hover:bg-slate-50 transition"
                >
                  {t.next}
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Confirmation Dialog */}
        {confirmDialog.open && confirmDialog.account && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <div className="w-full max-w-md bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl p-6 shadow-2xl space-y-4">
              <h3 className="text-base font-bold text-[#14233B] dark:text-[#E5EAF2]">
                {confirmDialog.type === 'approve'
                  ? t.dialogApproveTitle
                  : confirmDialog.type === 'suspend'
                  ? t.dialogSuspendTitle
                  : t.dialogReactivateTitle}
              </h3>

              <p className="text-xs text-slate-600 dark:text-slate-400">
                {t.dialogConfirmPrompt(confirmDialog.account.name)}
              </p>

              {confirmDialog.type === 'suspend' && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                    {t.reasonOptional}
                  </label>
                  <textarea
                    value={confirmDialog.reason}
                    onChange={(e) =>
                      setConfirmDialog((prev) => ({ ...prev, reason: e.target.value }))
                    }
                    rows={2}
                    className="w-full p-2.5 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                    placeholder={t.reasonPlaceholder}
                  />
                </div>
              )}

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setConfirmDialog({ open: false, type: 'approve', account: null })}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-xl transition"
                >
                  {t.cancel}
                </button>
                <button
                  type="button"
                  disabled={actionLoading}
                  onClick={handleExecuteAction}
                  className={`px-4 py-2 text-xs font-semibold text-white rounded-xl transition flex items-center gap-1.5 ${
                    confirmDialog.type === 'suspend'
                      ? 'bg-amber-600 hover:bg-amber-500'
                      : 'bg-emerald-600 hover:bg-emerald-500'
                  }`}
                >
                  {actionLoading ? (
                    <span>{t.processing}</span>
                  ) : (
                    <span>{t.confirm}</span>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* CREATE ACCOUNT MODAL */}
        {showCreateModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm overflow-y-auto">
            <div className="relative w-full max-w-2xl bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-3xl shadow-2xl overflow-hidden my-8">
              
              {/* Modal Header */}
              <div className="px-6 py-5 bg-[#14233B] text-white flex items-center justify-between border-b border-[#B3945B]/30">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#1E3557] border border-[#B3945B]/40 flex items-center justify-center text-[#B3945B]">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-white">
                      {t.createAccountModalTitle}
                    </h3>
                    <p className="text-[11px] text-slate-300">
                      {t.createAccountModalSubtitle}
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={closeCreateModal}
                  className="p-1.5 rounded-lg text-slate-300 hover:text-white hover:bg-white/10 transition"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* SUCCESS VIEW: Credentials Hand-off Card */}
              {createdSuccessData ? (
                <div className="p-8 space-y-6 text-center">
                  <div className="w-16 h-16 rounded-full bg-emerald-100 dark:bg-emerald-950/60 border-2 border-emerald-500 mx-auto flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>

                  <div>
                    <h4 className="text-lg font-extrabold text-[#14233B] dark:text-[#E5EAF2]">
                      {t.successCreatedTitle}
                    </h4>
                    <p className="text-xs text-slate-600 dark:text-slate-400 mt-2 max-w-lg mx-auto">
                      {t.successCreatedNotice}
                    </p>
                  </div>

                  {/* Credentials Box */}
                  <div className="bg-slate-50 dark:bg-[#0B1220] border border-[#B3945B]/40 rounded-2xl p-5 text-right space-y-4 max-w-lg mx-auto">
                    <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
                      <span className="text-xs text-slate-500 dark:text-slate-400">{t.colAccountName}:</span>
                      <span className="text-xs font-bold text-[#14233B] dark:text-[#E5EAF2]">
                        {createdSuccessData.account.name}
                      </span>
                    </div>

                    <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
                      <span className="text-xs text-slate-500 dark:text-slate-400">{t.colOwnerName}:</span>
                      <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                        {createdSuccessData.user.full_name}
                      </span>
                    </div>

                    <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
                      <span className="text-xs font-bold text-slate-700 dark:text-slate-300">{t.labelAssignedEmail}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-[#1E3557] dark:text-[#B3945B]" dir="ltr">
                          {createdSuccessData.credentials.email}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleCopy(createdSuccessData.credentials.email, 'email')}
                          className="px-2 py-1 text-[10px] rounded-md bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-[#B3945B] hover:text-white transition"
                        >
                          {copiedField === 'email' ? t.copiedNotice : t.btnCopyCredentials}
                        </button>
                      </div>
                    </div>

                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-slate-700 dark:text-slate-300">{t.labelAssignedPassword}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-[#1E3557] dark:text-[#B3945B]" dir="ltr">
                          {createdSuccessData.credentials.password}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleCopy(createdSuccessData.credentials.password, 'password')}
                          className="px-2 py-1 text-[10px] rounded-md bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-[#B3945B] hover:text-white transition"
                        >
                          {copiedField === 'password' ? t.copiedNotice : t.btnCopyCredentials}
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="pt-4">
                    <button
                      type="button"
                      onClick={closeCreateModal}
                      className="px-8 py-3 bg-[#14233B] hover:bg-[#1E3557] text-[#B3945B] hover:text-white border border-[#B3945B]/40 rounded-xl text-xs sm:text-sm font-bold shadow-md transition"
                    >
                      {t.btnClose}
                    </button>
                  </div>
                </div>
              ) : (
                /* FORM VIEW */
                <form onSubmit={handleCreateSubmit} className="p-6 space-y-6">
                  {/* Step / Section Navigation Tabs */}
                  <div className="flex border-b border-slate-200 dark:border-slate-800">
                    <button
                      type="button"
                      onClick={() => setFormTab('user')}
                      className={`flex-1 pb-3 text-xs font-bold border-b-2 transition ${
                        formTab === 'user'
                          ? 'border-[#B3945B] text-[#14233B] dark:text-[#E5EAF2]'
                          : 'border-transparent text-slate-400 hover:text-slate-600'
                      }`}
                    >
                      {t.tabUserInfo}
                    </button>
                    <button
                      type="button"
                      onClick={() => setFormTab('business')}
                      className={`flex-1 pb-3 text-xs font-bold border-b-2 transition ${
                        formTab === 'business'
                          ? 'border-[#B3945B] text-[#14233B] dark:text-[#E5EAF2]'
                          : 'border-transparent text-slate-400 hover:text-slate-600'
                      }`}
                    >
                      {t.tabBusinessInfo}
                    </button>
                  </div>

                  {createError && (
                    <div className="p-3 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-300 text-xs font-medium">
                      {createError}
                    </div>
                  )}

                  {/* TAB 1: User Fields (Matches Flutter register_view.dart) */}
                  {formTab === 'user' && (
                    <div className="space-y-4">
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldFirstName}
                          </label>
                          <input
                            type="text"
                            required
                            value={formData.first_name}
                            onChange={(e) => setFormData((prev) => ({ ...prev, first_name: e.target.value }))}
                            placeholder="أحمد / Ahmed"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldLastName}
                          </label>
                          <input
                            type="text"
                            required
                            value={formData.last_name}
                            onChange={(e) => setFormData((prev) => ({ ...prev, last_name: e.target.value }))}
                            placeholder="محمد / Mohammed"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldUsername}
                          </label>
                          <input
                            type="text"
                            required
                            dir="ltr"
                            value={formData.username}
                            onChange={(e) => setFormData((prev) => ({ ...prev, username: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '') }))}
                            placeholder="username"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldPhone}
                          </label>
                          <input
                            type="tel"
                            dir="ltr"
                            value={formData.phone}
                            onChange={(e) => setFormData((prev) => ({ ...prev, phone: e.target.value }))}
                            placeholder="+967 77..."
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                          {t.fieldEmail}
                        </label>
                        <input
                          type="email"
                          required
                          dir="ltr"
                          value={formData.email}
                          onChange={(e) => setFormData((prev) => ({ ...prev, email: e.target.value }))}
                          placeholder="client@smartmerchant.com"
                          className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                        />
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldPassword}
                          </label>
                          <input
                            type="text"
                            required
                            dir="ltr"
                            value={formData.password}
                            onChange={(e) => setFormData((prev) => ({ ...prev, password: e.target.value }))}
                            placeholder="Min. 6 chars"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldPasswordConfirm}
                          </label>
                          <input
                            type="text"
                            required
                            dir="ltr"
                            value={formData.password_confirmation}
                            onChange={(e) => setFormData((prev) => ({ ...prev, password_confirmation: e.target.value }))}
                            placeholder="Repeat password"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                      </div>

                      <div className="flex justify-end pt-2">
                        <button
                          type="button"
                          onClick={() => setFormTab('business')}
                          className="px-5 py-2 bg-[#14233B] hover:bg-[#1E3557] text-[#B3945B] hover:text-white rounded-xl text-xs font-bold transition flex items-center gap-1.5"
                        >
                          <span>{t.tabBusinessInfo}</span>
                          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={isAr ? "M15 19l-7-7 7-7" : "M9 5l7 7-7 7"} />
                          </svg>
                        </button>
                      </div>
                    </div>
                  )}

                  {/* TAB 2: Business Fields (Matches Flutter business_setup_view.dart) */}
                  {formTab === 'business' && (
                    <div className="space-y-4">
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldBusinessName}
                          </label>
                          <input
                            type="text"
                            required
                            value={formData.business_name}
                            onChange={(e) => setFormData((prev) => ({ ...prev, business_name: e.target.value }))}
                            placeholder="متجر النور / Al-Noor Store"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldBusinessType}
                          </label>
                          <select
                            value={formData.business_type}
                            onChange={(e) => setFormData((prev) => ({ ...prev, business_type: e.target.value }))}
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          >
                            {businessTypes.map((type) => (
                              <option key={type.id} value={type.id}>
                                {type.label}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldCountry}
                          </label>
                          <input
                            type="text"
                            value={formData.country}
                            onChange={(e) => setFormData((prev) => ({ ...prev, country: e.target.value }))}
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldCity}
                          </label>
                          <input
                            type="text"
                            value={formData.city}
                            onChange={(e) => setFormData((prev) => ({ ...prev, city: e.target.value }))}
                            placeholder="صنعاء"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldCurrency}
                          </label>
                          <select
                            value={formData.currency}
                            onChange={(e) => setFormData((prev) => ({ ...prev, currency: e.target.value }))}
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          >
                            <option value="YER">YER (الريال اليمني)</option>
                            <option value="SAR">SAR (الريال السعودي)</option>
                            <option value="USD">USD (الدولار الأمريكي)</option>
                          </select>
                        </div>
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                          {t.fieldAddress}
                        </label>
                        <input
                          type="text"
                          value={formData.address}
                          onChange={(e) => setFormData((prev) => ({ ...prev, address: e.target.value }))}
                          placeholder="شارع، حي، مبنى..."
                          className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                        />
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldPrimaryPhone}
                          </label>
                          <input
                            type="tel"
                            dir="ltr"
                            value={formData.primary_phone}
                            onChange={(e) => setFormData((prev) => ({ ...prev, primary_phone: e.target.value }))}
                            placeholder="+967..."
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-slate-700 dark:text-slate-300 mb-1">
                            {t.fieldPrimaryEmail}
                          </label>
                          <input
                            type="email"
                            dir="ltr"
                            value={formData.primary_email}
                            onChange={(e) => setFormData((prev) => ({ ...prev, primary_email: e.target.value }))}
                            placeholder="biz@smartmerchant.com"
                            className="w-full px-3.5 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-[#1F2937] dark:text-[#E5EAF2] focus:outline-none focus:ring-2 focus:ring-[#1E3557] dark:focus:ring-[#B3945B]"
                          />
                        </div>
                      </div>

                      <div className="flex justify-between items-center pt-4 border-t border-slate-200 dark:border-slate-800">
                        <button
                          type="button"
                          onClick={() => setFormTab('user')}
                          className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition"
                        >
                          {t.previous}
                        </button>

                        <button
                          type="submit"
                          disabled={createLoading}
                          className="px-6 py-2.5 bg-[#14233B] hover:bg-[#1E3557] text-[#B3945B] hover:text-white border border-[#B3945B]/40 rounded-xl text-xs sm:text-sm font-bold shadow-md transition disabled:opacity-50 flex items-center gap-2"
                        >
                          {createLoading ? (
                            <>
                              <div className="w-4 h-4 border-2 border-[#B3945B] border-t-transparent rounded-full animate-spin" />
                              <span>{t.btnSubmittingCreateAccount}</span>
                            </>
                          ) : (
                            <span>{t.btnSubmitCreateAccount}</span>
                          )}
                        </button>
                      </div>
                    </div>
                  )}
                </form>
              )}
            </div>
          </div>
        )}

        {/* Approve & Setup Installments Modal */}
        <ApproveSubscriptionModal
          isOpen={!!approveModalAccount}
          account={approveModalAccount}
          onClose={() => setApproveModalAccount(null)}
          onSuccess={(updated) => {
            setSuccessMsg(
              isAr
                ? `تم تفعيل حساب ${updated.name} واعتماد عقد الأقساط وإرسال بريد التأكيد بنجاح!`
                : `Account ${updated.name} approved with installment contract!`
            );
            setAccounts((prev) => prev.map((a) => (a.id === updated.id ? { ...a, ...updated } : a)));
          }}
        />

        {/* Account Statement & Payments Modal */}
        <AccountStatementModal
          isOpen={!!statementAccountId}
          accountId={statementAccountId}
          onClose={() => setStatementAccountId(null)}
          onPaymentSuccess={() => fetchAccounts(currentPage)}
        />
      </div>
    </AdminLayout>
  );
}
