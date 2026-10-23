'use client';

import React, { useState, useEffect } from 'react';
import { adminApi } from '@/lib/admin-api';
import type { AccountStatementResponse, AdminAccount } from '@/lib/admin-types';
import { useAdminAuth } from '@/lib/admin-context';

interface AccountStatementModalProps {
  isOpen: boolean;
  onClose: () => void;
  accountId: string | null;
  onPaymentSuccess?: () => void;
}

export function AccountStatementModal({
  isOpen,
  onClose,
  accountId,
  onPaymentSuccess,
}: AccountStatementModalProps) {
  const { lang } = useAdminAuth();
  const isAr = lang === 'ar';

  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<AccountStatementResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Pay modal sub-dialog
  const [payingInstallment, setPayingInstallment] = useState<{
    id: string;
    subId: string;
    number: number;
    amount: number;
  } | null>(null);
  const [payAmount, setPayAmount] = useState<number>(0);
  const [payMethod, setPayMethod] = useState<string>('Cash');
  const [payRef, setPayRef] = useState<string>('');
  const [payNotes, setPayNotes] = useState<string>('');
  const [paySubmitting, setPaySubmitting] = useState(false);
  const [paySuccessMsg, setPaySuccessMsg] = useState<string | null>(null);

  const fetchStatement = () => {
    if (!accountId) return;
    setLoading(true);
    setError(null);
    adminApi.getAccountStatement(accountId)
      .then((res) => {
        setData(res);
        setLoading(false);
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : (isAr ? 'فشل تحميل كشف الحساب' : 'Failed to load statement'));
        setLoading(false);
      });
  };

  useEffect(() => {
    if (isOpen && accountId) {
      setData(null);
      setPayingInstallment(null);
      setPaySuccessMsg(null);
      fetchStatement();
    }
  }, [isOpen, accountId]);

  const openPayDialog = (subId: string, instId: string, number: number, amount: number) => {
    setPayingInstallment({ id: instId, subId, number, amount });
    setPayAmount(amount);
    setPayMethod('Kuraimi Transfer');
    setPayRef('');
    setPayNotes('');
    setPaySuccessMsg(null);
  };

  const handlePaySubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!payingInstallment) return;

    setPaySubmitting(true);
    setError(null);

    try {
      await adminApi.paySubscriptionInstallment(payingInstallment.subId, payingInstallment.id, {
        amount: Number(payAmount),
        payment_method: payMethod,
        reference_number: payRef.trim() || undefined,
        notes: payNotes.trim() || undefined,
      });

      setPaySuccessMsg(isAr ? `تم تسجيل سداد القسط رقم ${payingInstallment.number} بنجاح!` : 'Payment recorded successfully!');
      setPayingInstallment(null);
      fetchStatement();
      if (onPaymentSuccess) onPaymentSuccess();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : (isAr ? 'فشل تسجيل السداد' : 'Failed to record payment'));
    } finally {
      setPaySubmitting(false);
    }
  };

  if (!isOpen) return null;

  const sub = data?.active_subscription;
  const installments = data?.installments || [];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/60 backdrop-blur-xs overflow-y-auto">
      <div className="w-full max-w-3xl bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-2xl overflow-hidden my-6">
        {/* Header */}
        <div className="px-6 py-4 bg-gradient-to-r from-[#14233B] to-[#1E3557] text-white flex items-center justify-between border-b border-slate-700/50">
          <div>
            <h3 className="text-base font-bold flex items-center gap-2">
              <span>📋</span>
              <span>{isAr ? 'كشف حساب اشتراكات وأقساط التاجر' : 'Merchant Subscription & Installment Ledger'}</span>
            </h3>
            {data?.account && (
              <p className="text-xs text-slate-300 mt-0.5">
                {data.account.name} • {data.account.owner_name} ({data.account.email})
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-white/10 hover:bg-white/20 flex items-center justify-center text-slate-300 hover:text-white transition"
          >
            ✕
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-5 max-h-[80vh] overflow-y-auto">
          {error && (
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-300 text-xs rounded-xl">
              {error}
            </div>
          )}

          {paySuccessMsg && (
            <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 text-xs rounded-xl">
              {paySuccessMsg}
            </div>
          )}

          {loading ? (
            <div className="py-12 text-center text-xs text-slate-400">
              <div className="w-6 h-6 border-2 border-[#B3945B] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
              <span>{isAr ? 'جاري جلب كشف الحساب...' : 'Loading statement...'}</span>
            </div>
          ) : !sub ? (
            <div className="py-12 text-center text-xs text-slate-400">
              {isAr ? 'لا يوجد اشتراك نشط لهذا التاجر حالياً.' : 'No active subscription found for this account.'}
            </div>
          ) : (
            <>
              {/* Financial Summary Cards */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="p-3.5 bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 rounded-xl">
                  <span className="block text-[11px] text-slate-500">{isAr ? 'إجمالي قيمة العقد' : 'Total Contract'}</span>
                  <span className="text-sm font-bold text-slate-900 dark:text-white mt-1 block">
                    {Number(sub.total_amount).toLocaleString()} YER
                  </span>
                </div>

                <div className="p-3.5 bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-900 rounded-xl">
                  <span className="block text-[11px] text-emerald-600 dark:text-emerald-400">{isAr ? 'المبلغ المسدد' : 'Paid Amount'}</span>
                  <span className="text-sm font-bold text-emerald-700 dark:text-emerald-300 mt-1 block">
                    {Number(sub.amount_paid).toLocaleString()} YER
                  </span>
                </div>

                <div className="p-3.5 bg-amber-50/50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-900 rounded-xl">
                  <span className="block text-[11px] text-amber-600 dark:text-amber-400">{isAr ? 'المبلغ المتبقي' : 'Remaining Balance'}</span>
                  <span className="text-sm font-bold text-amber-700 dark:text-amber-300 mt-1 block">
                    {(Number(sub.total_amount) - Number(sub.amount_paid)).toLocaleString()} YER
                  </span>
                </div>

                <div className="p-3.5 bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 rounded-xl">
                  <span className="block text-[11px] text-slate-500">{isAr ? 'دورة السداد' : 'Frequency'}</span>
                  <span className="text-xs font-bold text-slate-800 dark:text-slate-200 mt-1 block">
                    {sub.installment_frequency}
                  </span>
                </div>
              </div>

              {/* Installments Table */}
              <div className="border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden">
                <div className="px-4 py-3 bg-slate-50 dark:bg-slate-800/40 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-800 dark:text-slate-200">
                    {isAr ? 'جدول الأقساط وسجل السداد' : 'Installment Schedule & Payments'}
                  </span>
                  <span className="text-[11px] text-slate-500">
                    {installments.length} {isAr ? 'أقساط' : 'Installments'}
                  </span>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-xs text-right">
                    <thead className="bg-slate-50/60 dark:bg-[#0B1220] text-slate-600 dark:text-slate-400 border-b border-slate-200 dark:border-slate-800 text-[11px]">
                      <tr>
                        <th className="py-2.5 px-3">#</th>
                        <th className="py-2.5 px-3">{isAr ? 'تاريخ الاستحقاق' : 'Due Date'}</th>
                        <th className="py-2.5 px-3">{isAr ? 'المبلغ المطلوب' : 'Amount'}</th>
                        <th className="py-2.5 px-3">{isAr ? 'المسدد' : 'Paid'}</th>
                        <th className="py-2.5 px-3">{isAr ? 'طريقة وسند الدفع' : 'Method / Ref'}</th>
                        <th className="py-2.5 px-3 text-center">{isAr ? 'الحالة' : 'Status'}</th>
                        <th className="py-2.5 px-3 text-center">{isAr ? 'الإجراء' : 'Action'}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60">
                      {installments.map((inst) => {
                        const isPaid = inst.status === 'Paid';
                        return (
                          <tr key={inst.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition">
                            <td className="py-2.5 px-3 font-bold text-slate-800 dark:text-slate-200">
                              {isAr ? `قسط ${inst.installment_number}` : `#${inst.installment_number}`}
                            </td>
                            <td className="py-2.5 px-3 text-slate-600 dark:text-slate-400">
                              {inst.due_date ? String(inst.due_date).split('T')[0] : '—'}
                            </td>
                            <td className="py-2.5 px-3 font-bold text-slate-900 dark:text-white">
                              {Number(inst.amount).toLocaleString()} YER
                            </td>
                            <td className="py-2.5 px-3 text-emerald-600 dark:text-emerald-400 font-semibold">
                              {Number(inst.paid_amount).toLocaleString()} YER
                            </td>
                            <td className="py-2.5 px-3 text-[11px] text-slate-500">
                              {inst.payment_method || '—'} {inst.transaction_reference ? `(${inst.transaction_reference})` : ''}
                            </td>
                            <td className="py-2.5 px-3 text-center">
                              {isPaid ? (
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                                  {isAr ? 'مسدد ✓' : 'Paid'}
                                </span>
                              ) : (
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
                                  {isAr ? 'مستحق ⏳' : 'Pending'}
                                </span>
                              )}
                            </td>
                            <td className="py-2.5 px-3 text-center">
                              {!isPaid && (
                                <button
                                  type="button"
                                  onClick={() => openPayDialog(sub.id, inst.id, inst.installment_number, Number(inst.amount) - Number(inst.paid_amount))}
                                  className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-[#14233B] text-[#B3945B] hover:bg-[#1E3557] hover:text-white transition shadow-xs"
                                >
                                  {isAr ? 'تسجيل سداد' : 'Record Pay'}
                                </button>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}

          {/* Sub-dialog: Record Payment Form */}
          {payingInstallment && (
            <div className="fixed inset-0 z-60 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
              <div className="w-full max-w-md bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl p-6 shadow-2xl space-y-4">
                <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-3">
                  <h4 className="text-sm font-bold text-slate-900 dark:text-white">
                    {isAr ? `تسجيل سداد القسط رقم ${payingInstallment.number}` : `Pay Installment #${payingInstallment.number}`}
                  </h4>
                  <button onClick={() => setPayingInstallment(null)} className="text-slate-400 hover:text-slate-600">✕</button>
                </div>

                <form onSubmit={handlePaySubmit} className="space-y-3">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                      {isAr ? 'المبلغ المسدد (YER)' : 'Payment Amount'}
                    </label>
                    <input
                      type="number"
                      step="100"
                      min="1"
                      value={payAmount}
                      onChange={(e) => setPayAmount(Number(e.target.value))}
                      className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                      {isAr ? 'طريقة السداد' : 'Payment Method'}
                    </label>
                    <select
                      value={payMethod}
                      onChange={(e) => setPayMethod(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                    >
                      <option value="Kuraimi Transfer">{isAr ? 'حوالة بنك الكريمي (Kuraimi)' : 'Kuraimi Transfer'}</option>
                      <option value="Cash">{isAr ? 'نقداً (Cash)' : 'Cash'}</option>
                      <option value="Bank Transfer">{isAr ? 'تحويل بنكي رسمي' : 'Bank Transfer'}</option>
                      <option value="OneCash">{isAr ? 'وان كاش / محفظة إلكترونية' : 'OneCash'}</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                      {isAr ? 'رقم السند أو رقم الحوالة' : 'Reference / Receipt Number'}
                    </label>
                    <input
                      type="text"
                      value={payRef}
                      onChange={(e) => setPayRef(e.target.value)}
                      placeholder="e.g. KM-123456"
                      className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                      {isAr ? 'ملاحظات السداد (اختياري)' : 'Notes'}
                    </label>
                    <input
                      type="text"
                      value={payNotes}
                      onChange={(e) => setPayNotes(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                    />
                  </div>

                  <div className="flex justify-end gap-2 pt-3">
                    <button
                      type="button"
                      onClick={() => setPayingInstallment(null)}
                      className="px-3 py-1.5 text-xs text-slate-500 hover:text-slate-800"
                    >
                      {isAr ? 'إلغاء' : 'Cancel'}
                    </button>
                    <button
                      type="submit"
                      disabled={paySubmitting}
                      className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-md transition disabled:opacity-50"
                    >
                      {paySubmitting ? (isAr ? 'جاري الحفظ...' : 'Saving...') : (isAr ? 'تأكيد السداد وتمديد الرخصة' : 'Confirm Payment')}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 bg-slate-50 dark:bg-slate-800/40 border-t border-slate-200 dark:border-slate-800 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition"
          >
            {isAr ? 'إغلاق' : 'Close'}
          </button>
        </div>
      </div>
    </div>
  );
}
