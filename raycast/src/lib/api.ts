import { getPreferenceValues, showToast, Toast } from "@raycast/api";
import type { OkResponse, PomodoroConfig, StatusResponse, TimerRequest } from "./types";

type Prefs = { host: string; port: string };

function baseUrl(): string {
  const { host, port } = getPreferenceValues<Prefs>();
  return `http://${host}:${port || "7878"}`;
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${baseUrl()}${path}`, {
    ...options,
    headers: { "Content-Type": "application/json", ...options?.headers },
    signal: AbortSignal.timeout(5000),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`Server error ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

export async function startTimer(req: TimerRequest): Promise<void> {
  const result = await request<OkResponse>("/timer", {
    method: "POST",
    body: JSON.stringify(req),
  });
  if (!result.ok) throw new Error(result.error ?? "Unknown error");
}

export async function stopTimer(): Promise<void> {
  await request<OkResponse>("/stop", { method: "POST" });
}

export async function pauseTimer(): Promise<void> {
  await request<OkResponse>("/pause", { method: "POST" });
}

export async function resumeTimer(): Promise<void> {
  await request<OkResponse>("/resume", { method: "POST" });
}

export async function skipTimer(): Promise<void> {
  await request<OkResponse>("/skip", { method: "POST" });
}

export async function enqueueTimer(req: TimerRequest): Promise<void> {
  await request<OkResponse>("/queue", {
    method: "POST",
    body: JSON.stringify(req),
  });
}

export async function startPomodoro(config?: PomodoroConfig): Promise<void> {
  await request<OkResponse>("/pomodoro", {
    method: "POST",
    body: JSON.stringify(config ?? {}),
  });
}

export async function getStatus(): Promise<StatusResponse> {
  return request<StatusResponse>("/status");
}

export async function setTheme(theme: string): Promise<void> {
  await request<OkResponse>("/settings", {
    method: "POST",
    body: JSON.stringify({ theme }),
  });
}

export function formatRemaining(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export async function withErrorToast<T>(fn: () => Promise<T>): Promise<T | undefined> {
  try {
    return await fn();
  } catch (err) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Pulse Error",
      message: err instanceof Error ? err.message : String(err),
    });
    return undefined;
  }
}
