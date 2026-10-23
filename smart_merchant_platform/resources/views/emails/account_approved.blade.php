<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>تهانينا! تم تفعيل حسابك في تاجركم</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f1f5f9;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      color: #1e293b;
      line-height: 1.6;
      direction: rtl;
      text-align: right;
    }
    .wrapper {
      width: 100%;
      background-color: #f1f5f9;
      padding: 40px 16px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 20px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.06);
      border: 1px solid #e2e8f0;
    }
    .header {
      background: linear-gradient(135deg, #091738 0%, #0F2A6E 50%, #1D4ED8 100%);
      padding: 36px 30px;
      text-align: center;
      color: #ffffff;
    }
    .logo-badge {
      display: inline-block;
      width: 64px;
      height: 64px;
      background-color: #ffffff;
      border-radius: 18px;
      padding: 6px;
      margin-bottom: 16px;
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
    }
    .logo-inner {
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, #0F2A6E, #1D4ED8);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #E2BA65;
      font-size: 28px;
      font-weight: bold;
      line-height: 52px;
      text-align: center;
    }
    .header-title {
      font-size: 24px;
      font-weight: 800;
      margin: 0 0 6px 0;
      color: #ffffff;
    }
    .header-subtitle {
      font-size: 13px;
      color: rgba(255, 255, 255, 0.85);
      margin: 0;
    }
    .content {
      padding: 32px 30px;
    }
    .greeting {
      font-size: 18px;
      font-weight: 800;
      color: #0f172a;
      margin-bottom: 12px;
    }
    .message {
      font-size: 14.5px;
      color: #475569;
      margin-bottom: 24px;
    }
    .status-badge {
      display: inline-block;
      background-color: #ecfdf5;
      color: #047857;
      border: 1px solid #a7f3d0;
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: bold;
      margin-bottom: 24px;
    }
    .details-card {
      background-color: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 16px;
      padding: 20px;
      margin-bottom: 28px;
    }
    .details-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
      border-bottom: 1px solid #edf2f7;
      font-size: 13.5px;
    }
    .details-row:last-child {
      border-bottom: none;
      padding-bottom: 0;
    }
    .details-label {
      color: #64748b;
      font-weight: 600;
    }
    .details-value {
      color: #0f172a;
      font-weight: bold;
    }
    .features-grid {
      background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%);
      border: 1px solid #bbf7d0;
      border-radius: 16px;
      padding: 18px 20px;
      margin-bottom: 28px;
    }
    .feature-item {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
      font-size: 13px;
      color: #065f46;
      font-weight: 600;
    }
    .feature-item:last-child {
      margin-bottom: 0;
    }
    .feature-icon {
      margin-left: 10px;
      font-size: 16px;
    }
    .cta-container {
      text-align: center;
      margin: 32px 0 24px 0;
    }
    .cta-button {
      display: inline-block;
      background: linear-gradient(135deg, #1D4ED8 0%, #2563EB 100%);
      color: #ffffff !important;
      text-decoration: none;
      font-size: 15px;
      font-weight: bold;
      padding: 14px 36px;
      border-radius: 14px;
      box-shadow: 0 6px 20px rgba(29, 78, 216, 0.35);
    }
    .support-box {
      border-top: 1px solid #e2e8f0;
      padding-top: 24px;
      text-align: center;
      color: #64748b;
      font-size: 12.5px;
    }
    .support-box a {
      color: #1D4ED8;
      text-decoration: none;
      font-weight: bold;
    }
    .footer {
      background-color: #091738;
      padding: 24px 30px;
      text-align: center;
      color: #94a3b8;
      font-size: 11.5px;
    }
    .footer p {
      margin: 4px 0;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <!-- Header -->
      <div class="header">
        <div class="logo-badge">
          <div class="logo-inner">ت</div>
        </div>
        <h1 class="header-title">تاجركم • Tajer</h1>
        <p class="header-subtitle">المنظومة المتكاملة لإدارة وتجارة المتاجر والشركات</p>
      </div>

      <!-- Main Content -->
      <div class="content">
        <div class="status-badge">
          ✓ تم تفعيل واعتماد الحساب بنجاح
        </div>

        <div class="greeting">
          مرحباً بك أستاذ {{ $account->owner_name ?? 'التاجر العزيز' }}،
        </div>

        <p class="message">
          يسعدنا إعلامك بأنه قد تمت مراجعة واعتماد طلب انضمامكم إلى منصة <strong>«تاجركم»</strong> بنجاح. حسابكم التجاري الآن نشط ومفعّل بالكامل وجاهز للاستخدام.
        </p>

        <!-- Details Card -->
        <div class="details-card">
          <div class="details-row">
            <span class="details-label">اسم المنشأة / المتجر:</span>
            <span class="details-value">{{ $business->business_name ?? $account->name }}</span>
          </div>
          <div class="details-row">
            <span class="details-label">نوع النشاط التجاري:</span>
            <span class="details-value">{{ $business->business_type ?? 'تجزئة عامة' }}</span>
          </div>
          <div class="details-row">
            <span class="details-label">رقم الهاتف المعتمد:</span>
            <span class="details-value" dir="ltr">{{ $account->phone ?? ($user->phone ?? '—') }}</span>
          </div>
          <div class="details-row">
            <span class="details-label">البريد الإلكتروني المعتمد:</span>
            <span class="details-value" dir="ltr">{{ $account->email }}</span>
          </div>
          <div class="details-row">
            <span class="details-label">حالة الحساب:</span>
            <span class="details-value" style="color: #047857;">مفعّل ونشط (Active)</span>
          </div>
        </div>

        <!-- Features Activated -->
        <div class="features-grid">
          <div class="feature-item">
            <span class="feature-icon">⚡</span>
            <span>إدارة نقاط البيع والمبيعات والمخزون مع إمكانية العمل بدون إنترنت</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">🛍️</span>
            <span>متجر إلكتروني فوري جاهز لمشاركة رابط منتجاتك وتلقي الطلبات مباشرة</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">💬</span>
            <span>ربط مباشر وفوري مع الواتساب وبدون أي عمولة على مبيعاتك</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📊</span>
            <span>تقارير مالية وجرد مخزون لحظي ودقيق لحماية أرباحك</span>
          </div>
        </div>

        <!-- Call to Action -->
        <div class="cta-container">
          <a href="{{ config('app.url', 'http://localhost:3000') }}" class="cta-button">
            تسجيل الدخول وبدء استخدام النظام
          </a>
        </div>

        <!-- Support Info -->
        <div class="support-box">
          <p>إذا كانت لديك أي استفسارات أو تحتاج إلى مساعدة في تهيئة الفروع والأصناف، فريق دعم تاجركم متاح لمساعدتكم دائماً.</p>
          <p>راسلنا عبر الواتساب أو تواصل مع مدير حسابك المعتمد.</p>
        </div>
      </div>

      <!-- Footer -->
      <div class="footer">
        <p>© 2026 تاجركم (Tajer). جميع الحقوق محفوظة.</p>
        <p>صُمم خصيصاً لراحة التجار ورواد الأعمال في اليمن والعالم العربي.</p>
      </div>
    </div>
  </div>
</body>
</html>
