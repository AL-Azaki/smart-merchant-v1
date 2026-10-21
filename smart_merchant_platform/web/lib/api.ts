import { STOREFRONT_API_PREFIX } from './config';
import type {
  ApiError,
  CreateOrderPayload,
  OrderSuccessResponse,
  PaginatedResponse,
  StoreBootstrap,
  StoreCategory,
  StoreProductDetail,
  StoreProductListItem,
} from './types';

/* ──────────────────────────────────────────────
   Centralized Fetch Wrapper
   ────────────────────────────────────────────── */

async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const url = `${STOREFRONT_API_PREFIX}${path}`;

  let res: Response;
  try {
    res = await fetch(url, {
      ...options,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
  } catch {
    throw createApiError('خطأ في الاتصال بالخادم. تحقق من اتصالك بالإنترنت.', 0, false);
  }

  if (res.ok) {
    // handle 204 No Content
    if (res.status === 204) return {} as T;
    try {
      return await res.json() as T;
    } catch {
      throw createApiError('استجابة غير متوقعة من الخادم', res.status, false);
    }
  }

  // Error path
  let body: Record<string, unknown> | null = null;
  try {
    body = await res.json() as Record<string, unknown>;
  } catch {
    // non-JSON error response
  }

  const message = (body?.message as string) || getDefaultMessage(res.status);
  const code = (body?.code as string) || undefined;
  const isValidation = res.status === 422;
  const validationErrors = isValidation && body?.errors
    ? (body.errors as Record<string, string[]>)
    : undefined;

  throw createApiError(message, res.status, isValidation, validationErrors, code);
}

function createApiError(
  message: string,
  status: number,
  isValidation: boolean,
  validationErrors?: Record<string, string[]>,
  code?: string,
): ApiError {
  return { message, status, isValidation, validationErrors, code };
}

function getDefaultMessage(status: number): string {
  switch (status) {
    case 400: return 'طلب غير صالح';
    case 403: return 'المتجر مغلق حالياً';
    case 404: return 'الصفحة أو المحتوى غير موجود';
    case 409: return 'تم إرسال هذا الطلب مسبقاً';
    case 422: return 'يوجد خطأ في البيانات المدخلة';
    case 429: return 'عدد الطلبات كثير جداً. انتظر قليلاً وحاول مجدداً';
    case 500: return 'خطأ في الخادم. حاول مجدداً لاحقاً';
    default:  return 'حدث خطأ غير متوقع';
  }
}

/* ──────────────────────────────────────────────
   Public API Functions
   ────────────────────────────────────────────── */

export async function getStoreBootstrap(slug: string): Promise<{ data: StoreBootstrap }> {
  return apiFetch<{ data: StoreBootstrap }>(`/${encodeURIComponent(slug)}/bootstrap`, {
    cache: 'no-store',
  });
}

export async function getCategories(
  slug: string,
  options?: { onlyWithProducts?: boolean },
): Promise<{ data: StoreCategory[] }> {
  const params = new URLSearchParams();
  if (options?.onlyWithProducts) params.set('only_with_products', '1');
  const qs = params.toString();
  return apiFetch<{ data: StoreCategory[] }>(
    `/${encodeURIComponent(slug)}/categories${qs ? `?${qs}` : ''}`,
    { cache: 'no-store' },
  );
}

export async function getProducts(
  slug: string,
  filters?: { category_id?: string; search?: string; page?: number; per_page?: number },
): Promise<PaginatedResponse<StoreProductListItem>> {
  const params = new URLSearchParams();
  if (filters?.category_id) params.set('category_id', filters.category_id);
  if (filters?.search) params.set('search', filters.search);
  if (filters?.page) params.set('page', String(filters.page));
  if (filters?.per_page) params.set('per_page', String(filters.per_page));
  const qs = params.toString();
  return apiFetch<PaginatedResponse<StoreProductListItem>>(
    `/${encodeURIComponent(slug)}/products${qs ? `?${qs}` : ''}`,
    { cache: 'no-store' },
  );
}

export async function getProductDetail(
  slug: string,
  productId: string,
): Promise<{ data: StoreProductDetail }> {
  return apiFetch<{ data: StoreProductDetail }>(
    `/${encodeURIComponent(slug)}/products/${encodeURIComponent(productId)}`,
    { next: { revalidate: 30 } },
  );
}

export async function createOrder(
  slug: string,
  payload: CreateOrderPayload,
): Promise<OrderSuccessResponse> {
  return apiFetch<OrderSuccessResponse>(
    `/${encodeURIComponent(slug)}/orders`,
    {
      method: 'POST',
      body: JSON.stringify(payload),
      cache: 'no-store',
    },
  );
}

/* ──────────────────────────────────────────────
   Error type guard
   ────────────────────────────────────────────── */
export function isApiError(err: unknown): err is ApiError {
  return typeof err === 'object' && err !== null && 'status' in err && 'message' in err;
}
