import { showHUD, showToast, Toast } from "@raycast/api";
import { formatRemaining, getStatus, withErrorToast } from "./lib/api";

export default async function TimerStatus() {
  await showToast({ style: Toast.Style.Animated, title: "Checking status..." });

  const status = await withErrorToast(getStatus);
  if (!status) return;

  if (status.status === "idle") {
    await showHUD("No timer running");
    return;
  }

  const time = formatRemaining(status.remaining);
  const label = status.label ? `${status.label} — ` : "";
  const state = status.paused ? " (paused)" : "";
  const queue = status.queue.length > 0 ? ` | ${status.queue.length} queued` : "";
  await showHUD(`${label}${time} remaining${state}${queue}`);
}
