import { showToast, Toast } from "@raycast/api";
import { stopTimer, withErrorToast } from "./lib/api";

export default async function StopTimer() {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Stopping timer…" });
  const ok = await withErrorToast(stopTimer);
  if (ok !== undefined) {
    toast.style = Toast.Style.Success;
    toast.title = "Timer stopped";
  }
}
