'use client';

import React, { useState, useEffect } from 'react';
import { adminApi } from '@/lib/admin-api';
import type { AdminAccount, ApproveAccountPayload, SubscriptionPlan } from '@/lib/admin-types';
import { useAdminAuth } from '@/lib/admin-context';

interface ApproveSubscriptionModalProps {
  isOpen: boolean;
  onClose: () => void;
  account: AdminAccount | null;
  onSuccess: (updated: AdminAccount) => void;
}

export function ApproveSubscriptionModal({
  isOpen,
  onClose,
  account,
  onSuccess,
}: ApproveSubscriptionModalProps) {
  const { lang, t } = useAdminAuth();
  const isAr = lang === 'ar';

  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loadingPlans, setLoadingPlans] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form states
  const [selectedPlanId, setSelectedPlanId] = useState<string>('');
  const [totalAmount, setTotalAmount] = useState<number>(120000);
  const [downPayment, setDownPayment] = useState<number>(30000);
  const [frequency, setFrequency] = useState<string>('Every3Months');
  const [installmentsCount, setInstallmentsCount] = useState<number>(4);
  const [startDate, setStartDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [maxOfflineDays, setMaxOfflineDays] = useState<number>(7);
  const [gracePeriodDays, setGracePeriodDays] = useState<number>(3);
  const [notes, setNotes] = useState<string>('');

  // Fetch plans on open
  useEffect(() => {
    if (isOpen) {
      setError(null);
      setLoadingPlans(true);
      adminApi.getPlans()
        .then((res) => {
          setPlans(res);
          if (res.length > 0) {
            setSelectedPlanId(res[0].id);
            const price = Number(res[0].price);
            if (price > 0) {
              setTotalAmount(price);
              setDownPayment(Math.round(price * 0.25));
            }
          }
          setLoadingPlans(false);
        })
        .catch(() => {
          setLoadingPlans(false);
        });
    }
  }, [isOpen]);

  // Handle plan change
  const handlePlanChange = (planId: string) => {
    setSelectedPlanId(planId);
    const plan = plans.find((p) => p.id === planId);
    if (plan && Number(plan.price) > 0) {
      const p = Number(plan.price);
      setTotalAmount(p);
      setDownPayment(Math.round(p * 0.25));
    }
  };

  // Calculate live preview schedule
  const calculatePreviewSchedule = () => {
    const list: Array<{
      number: number;
      dueDate: string;
      amount: number;
      status: 'Paid' | 'Pending';
      notes: string;
    }> = [];

    const start = new Date(startDate || new Date().toISOString().split('T')[0]);
    let currentInstNum = 1;

    if (downPayment > 0) {
      list.push({
        number: currentInstNum++,
        dueDate: start.toISOString().split('T')[0],
        amount: downPayment,
        status: 'Paid',
        notes: isAr ? 'الدفعة الأولى المقدمة' : 'Down payment',
      });
    }

    const remaining = Math.max(0, totalAmount - downPayment);
    const unpaidCount = downPayment > 0 ? Math.max(1, installmentsCount - 1) : installmentsCount;
    const baseAmount = Math.floor((remaining / unpaidCount) * 100) / 100;
    const remainder = Math.round((remaining - baseAmount * unpaidCount) * 100) / 100;

    const monthsToAdd = frequency === 'Monthly' ? 1 :
      frequency === 'Every2Months' ? 2 :
      frequency === 'Every3Months' ? 3 :
      frequency === 'Every4Months' ? 4 :
      frequency === 'SemiAnnual' ? 6 :
      frequency === 'Yearly' ? 12 : 1;

    for (let i = 0; i < unpaidCount; i++) {
      const d = new Date(start);
      d.setMonth(d.getMonth() + monthsToAdd * (i + 1));
      const amt = i === 0 && remainder > 0 ? baseAmount + remainder : baseAmount;

      list.push({
        number: currentInstNum++,
        dueDate: d.toISOString().split('T')[0],
        amount: amt,
        status: 'Pending',
        notes: isAr ? `القسط ${i + 1} (${frequency})` : `Installment ${i + 1}`,
      });
    }

    return list;
  };

  const previewSchedule = calculatePreviewSchedule();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!account) return;

    setSubmitting(true);
    setError(null);

    const payload: ApproveAccountPayload = {
      plan_id: selectedPlanId || undefined,
      total_amount: Number(totalAmount),
      down_payment: Number(downPayment),
      installment_frequency: frequency,
      installments_count: Number(installmentsCount),
      start_date: startDate,
      max_offline_days: Number(maxOfflineDays),
      grace_period_days: Number(gracePeriodDays),
      notes: notes.trim() || undefined,
    };

    try {
      const updated = await adminApi.approveAccount(account.id, payload);
      onSuccess(updated);
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : (isAr ? 'فشل تفعيل الحساب' : 'Failed to activate account'));
    } finally {
      setSubmitting(false);
    }
  };

  if (!isOpen || !account) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/60 backdrop-blur-xs overflow-y-auto">
      <div className="w-full max-w-2xl bg-white dark:bg-[#111C2F] border border-[#E2E8F0] dark:border-[#1E293B] rounded-2xl shadow-2xl overflow-hidden my-6">
        {/* Modal Header */}
        <div className="px-6 py-4 bg-gradient-to-r from-[#14233B] to-[#1E3557] text-white flex items-center justify-between border-b border-slate-700/50">
          <div>
            <h3 className="text-base font-bold flex items-center gap-2">
              <span>🌟</span>
              <span>{isAr ? 'تفعيل الحساب وتحديد خطة الأقساط' : 'Approve Account & Setup Installments'}</span>
            </h3>
            <p className="text-xs text-slate-300 mt-0.5">
              {account.name} • {account.owner_name} ({account.email})
            </p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-white/10 hover:bg-white/20 flex items-center justify-center text-slate-300 hover:text-white transition"
          >
            ✕
          </button>
        </div>

        {/* Modal Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-5 max-h-[80vh] overflow-y-auto">
          {error && (
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-300 text-xs rounded-xl">
              {error}
            </div>
          )}

          {/* Plan & Pricing */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'خطة الاشتراك الأساسية' : 'Subscription Plan'}
              </label>
              {loadingPlans ? (
                <div className="text-xs text-slate-400 py-2">{isAr ? 'جاري تحميل الخطط...' : 'Loading plans...'}</div>
              ) : (
                <select
                  value={selectedPlanId}
                  onChange={(e) => handlePlanChange(e.target.value)}
                  className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                >
                  {plans.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.plan_name} ({Number(p.price).toLocaleString()} YER)
                    </option>
                  ))}
                </select>
              )}
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'إجمالي قيمة العقد (YER)' : 'Total Contract Amount'}
              </label>
              <input
                type="number"
                min="0"
                step="1000"
                value={totalAmount}
                onChange={(e) => setTotalAmount(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                required
              />
            </div>
          </div>

          {/* Installment Frequency & Counts */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'وتيرة ودورة القسط' : 'Installment Cycle'}
              </label>
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
              >
                <option value="Monthly">{isAr ? 'شهرياً (كل شهر)' : 'Monthly'}</option>
                <option value="Every2Months">{isAr ? 'كل شهرين' : 'Every 2 Months'}</option>
                <option value="Every3Months">{isAr ? 'كل 3 أشهر (ربع سنوي)' : 'Every 3 Months'}</option>
                <option value="Every4Months">{isAr ? 'كل 4 أشهر' : 'Every 4 Months'}</option>
                <option value="SemiAnnual">{isAr ? 'كل 6 أشهر (نصف سنوي)' : 'Semi-Annual'}</option>
                <option value="Yearly">{isAr ? 'سنوياً' : 'Yearly'}</option>
                <option value="SinglePayment">{isAr ? 'دفعة واحدة كاملة' : 'Single Payment'}</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'عدد الأقساط الإجمالي' : 'Total Installments'}
              </label>
              <input
                type="number"
                min="1"
                max="24"
                value={installmentsCount}
                onChange={(e) => setInstallmentsCount(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'الدفعة الأولى المقدمة' : 'Down Payment'}
              </label>
              <input
                type="number"
                min="0"
                max={totalAmount}
                step="500"
                value={downPayment}
                onChange={(e) => setDownPayment(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
              />
            </div>
          </div>

          {/* Offline Security & Dates */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'تاريخ بداية العقد' : 'Start Date'}
              </label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'مهلة الأوفلاين القصوى (أيام)' : 'Max Offline Days'}
              </label>
              <input
                type="number"
                min="1"
                max="90"
                value={maxOfflineDays}
                onChange={(e) => setMaxOfflineDays(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
                {isAr ? 'أيام السماح بعد القسط' : 'Grace Period Days'}
              </label>
              <input
                type="number"
                min="0"
                max="30"
                value={gracePeriodDays}
                onChange={(e) => setGracePeriodDays(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
              />
            </div>
          </div>

          {/* Live Schedule Preview Table */}
          <div className="bg-slate-50 dark:bg-[#0B1220] border border-slate-200 dark:border-slate-800 rounded-xl p-3.5 space-y-2">
            <div className="flex items-center justify-between text-xs font-bold text-slate-800 dark:text-slate-200">
              <span>📋 {isAr ? 'معاينة جدول الأقساط المستحقة وكشف الحساب' : 'Installment Schedule Preview'}</span>
              <span className="text-[#B3945B]">
                {isAr ? `المتبقي: ${(totalAmount - downPayment).toLocaleString()} YER` : `Balance: ${(totalAmount - downPayment).toLocaleString()}`}
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-xs text-right">
                <thead>
                  <tr className="border-b border-slate-200 dark:border-slate-800 text-[11px] text-slate-500">
                    <th className="py-1.5 px-2">#</th>
                    <th className="py-1.5 px-2">{isAr ? 'تاريخ الاستحقاق' : 'Due Date'}</th>
                    <th className="py-1.5 px-2">{isAr ? 'المبلغ' : 'Amount'}</th>
                    <th className="py-1.5 px-2">{isAr ? 'الحالة' : 'Status'}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200/50 dark:divide-slate-800/50">
                  {previewSchedule.map((row) => (
                    <tr key={row.number}>
                      <td className="py-1.5 px-2 font-bold">{isAr ? `قسط ${row.number}` : `#${row.number}`}</td>
                      <td className="py-1.5 px-2 text-slate-600 dark:text-slate-400">{row.dueDate}</td>
                      <td className="py-1.5 px-2 font-bold text-slate-900 dark:text-white">{row.amount.toLocaleString()} YER</td>
                      <td className="py-1.5 px-2">
                        {row.status === 'Paid' ? (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                            {isAr ? 'مسدد (دفعة أولى)' : 'Paid'}
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
                            {isAr ? 'مستحق لاحقاً' : 'Pending'}
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1">
              {isAr ? 'ملاحظات العقد أو شروط خاصة (اختياري)' : 'Contract Notes (Optional)'}
            </label>
            <textarea
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={isAr ? 'أي ملاحظات يتم تضمينها في كشف الحساب...' : 'Notes...'}
              className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-[#0B1220] border border-[#E2E8F0] dark:border-[#1E293B] rounded-xl text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#B3945B]"
            />
          </div>

          {/* Modal Footer */}
          <div className="flex justify-end items-center gap-3 pt-3 border-t border-slate-200 dark:border-slate-800">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition"
            >
              {t.cancel}
            </button>

            <button
              type="submit"
              disabled={submitting}
              className="px-6 py-2.5 bg-[#14233B] hover:bg-[#1E3557] text-[#B3945B] hover:text-white border border-[#B3945B]/40 rounded-xl text-xs sm:text-sm font-bold shadow-md transition disabled:opacity-50 flex items-center gap-2"
            >
              {submitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-[#B3945B] border-t-transparent rounded-full animate-spin" />
                  <span>{isAr ? 'جاري الاعتماد وإرسال الإيميل...' : 'Approving...'}</span>
                </>
              ) : (
                <span>{isAr ? '✓ تأكيد التفعيل واعتماد خطة الأقساط' : 'Confirm & Activate Subscription'}</span>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
