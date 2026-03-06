import { Action, ActionPanel, Form, showToast, Toast, useNavigation } from "@raycast/api";
import { useState } from "react";
import { startPomodoro, withErrorToast } from "./lib/api";

export default function StartPomodoro() {
  const { pop } = useNavigation();
  const [focus, setFocus] = useState("25");
  const [shortBreak, setShortBreak] = useState("5");
  const [longBreak, setLongBreak] = useState("15");
  const [cycles, setCycles] = useState("4");

  async function handleSubmit() {
    const toast = await showToast({ style: Toast.Style.Animated, title: "Starting pomodoro..." });
    const ok = await withErrorToast(() =>
      startPomodoro({
        focusMinutes: parseInt(focus) || 25,
        shortBreakMinutes: parseInt(shortBreak) || 5,
        longBreakMinutes: parseInt(longBreak) || 15,
        totalCycles: parseInt(cycles) || 4,
      })
    );
    if (ok !== undefined) {
      toast.style = Toast.Style.Success;
      toast.title = "Pomodoro started";
      toast.message = `${focus}m focus x ${cycles} cycles`;
      pop();
    }
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Start Pomodoro" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextField id="focus" title="Focus (min)" value={focus} onChange={setFocus} placeholder="25" />
      <Form.TextField
        id="shortBreak"
        title="Short Break (min)"
        value={shortBreak}
        onChange={setShortBreak}
        placeholder="5"
      />
      <Form.TextField
        id="longBreak"
        title="Long Break (min)"
        value={longBreak}
        onChange={setLongBreak}
        placeholder="15"
      />
      <Form.TextField id="cycles" title="Cycles" value={cycles} onChange={setCycles} placeholder="4" />
    </Form>
  );
}
