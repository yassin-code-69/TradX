import { supabase } from "@/lib/supabase/client";

export class ApiError extends Error {
  status: number;
  code?: string;
  data?: unknown;

  constructor(message: string, status: number, code?: string, data?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.data = data;
  }
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    message: string;
    code?: string;
    details?: unknown;
  };
  meta?: Record<string, unknown>;
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl.replace(/\/$/, "");
  }

  private async getAuthToken(): Promise<string | null> {
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      return session?.access_token || null;
    } catch {
      return null;
    }
  }

  private generateRequestId(): string {
    if (typeof crypto !== "undefined" && crypto.randomUUID) {
      return crypto.randomUUID();
    }
    return `req-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  }

  public async request<T>(
    endpoint: string,
    options: RequestInit = {},
  ): Promise<T> {
    const url = endpoint.startsWith("http")
      ? endpoint
      : `${this.baseUrl}${endpoint.startsWith("/") ? "" : "/"}${endpoint}`;

    const headers = new Headers(options.headers || {});

    // Inject Bearer token if not already provided
    if (!headers.has("Authorization")) {
      const token = await this.getAuthToken();
      if (token) {
        headers.set("Authorization", `Bearer ${token}`);
      }
    }

    // Set Request ID
    if (!headers.has("X-Request-ID")) {
      headers.set("X-Request-ID", this.generateRequestId());
    }

    // Set default Content-Type to JSON if there is a body and it's not FormData
    if (
      options.body &&
      !(options.body instanceof FormData) &&
      !headers.has("Content-Type")
    ) {
      headers.set("Content-Type", "application/json");
    }

    // Ensure Accept header is set
    if (!headers.has("Accept")) {
      headers.set("Accept", "application/json");
    }

    const config: RequestInit = {
      ...options,
      headers,
    };

    let response: Response;
    try {
      response = await fetch(url, config);
    } catch (networkError) {
      throw new ApiError(
        networkError instanceof Error
          ? networkError.message
          : "Network connection failed",
        0,
        "NETWORK_ERROR",
      );
    }

    // Handle 401 Unauthorized
    if (response.status === 401 && typeof window !== "undefined") {
      window.dispatchEvent(
        new CustomEvent("tradex:unauthorized", {
          detail: { url, status: 401 },
        }),
      );
    }

    // Parse response
    const contentType = response.headers.get("content-type");
    const isJson = contentType?.includes("application/json");

    let responseData: unknown = null;
    if (isJson) {
      try {
        responseData = await response.json();
      } catch {
        responseData = null;
      }
    } else {
      responseData = await response.text();
    }

    if (!response.ok) {
      const errObj = responseData as {
        error?: { message?: string; code?: string; details?: unknown };
        message?: string;
      } | null;

      const errorMessage =
        errObj?.error?.message ||
        errObj?.message ||
        `Request failed with status ${response.status}: ${response.statusText}`;

      const errorCode = errObj?.error?.code;
      const errorDetails = errObj?.error?.details || responseData;

      throw new ApiError(
        errorMessage,
        response.status,
        errorCode,
        errorDetails,
      );
    }

    // If backend envelope wraps in { success: true, data: ... }, return that data or the full response
    if (
      responseData &&
      typeof responseData === "object" &&
      "data" in responseData &&
      "success" in responseData
    ) {
      return (responseData as { data: T }).data;
    }

    return responseData as T;
  }

  public get<T>(endpoint: string, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: "GET" });
  }

  public post<T>(
    endpoint: string,
    body?: unknown,
    options?: RequestInit,
  ): Promise<T> {
    return this.request<T>(endpoint, {
      ...options,
      method: "POST",
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  }

  public put<T>(
    endpoint: string,
    body?: unknown,
    options?: RequestInit,
  ): Promise<T> {
    return this.request<T>(endpoint, {
      ...options,
      method: "PUT",
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  }

  public patch<T>(
    endpoint: string,
    body?: unknown,
    options?: RequestInit,
  ): Promise<T> {
    return this.request<T>(endpoint, {
      ...options,
      method: "PATCH",
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  }

  public delete<T>(endpoint: string, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: "DELETE" });
  }
}

export const apiClient = new ApiClient(API_BASE_URL);
export default apiClient;
