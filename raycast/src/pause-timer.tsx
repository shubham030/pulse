import { showToast, Toast } from "@raycast/api";
import { pauseTimer, withErrorToast } from "./lib/api";

export default async function PauseTimer() {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Pausing timer..." });
  const ok = await withErrorToast(pauseTimer);
  if (ok !== undefined) {
    toast.style = Toast.Style.Success;
    toast.title = "Timer paused";
  }
}
