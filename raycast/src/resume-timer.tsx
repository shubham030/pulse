import { showToast, Toast } from "@raycast/api";
import { resumeTimer, withErrorToast } from "./lib/api";

export default async function ResumeTimer() {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Resuming timer..." });
  const ok = await withErrorToast(resumeTimer);
  if (ok !== undefined) {
    toast.style = Toast.Style.Success;
    toast.title = "Timer resumed";
  }
}
