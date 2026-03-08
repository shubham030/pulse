import {
  Action,
  ActionPanel,
  Form,
  Icon,
  List,
  showToast,
  Toast,
  useNavigation,
} from "@raycast/api";
import { useState } from "react";
import { startTimer, withErrorToast } from "./lib/api";

type Preset = {
  title: string;
  subtitle: string;
  duration: number; // seconds
  icon: Icon;
};

const PRESETS: Preset[] = [
  { title: "Short Break", subtitle: "5 min", duration: 5 * 60, icon: Icon.Leaf },
  { title: "Focus", subtitle: "25 min", duration: 25 * 60, icon: Icon.Bolt },
  { title: "Long Break", subtitle: "15 min", duration: 15 * 60, icon: Icon.Leaf },
  { title: "Deep Work", subtitle: "90 min", duration: 90 * 60, icon: Icon.BullsEye },
];

async function launch(duration: number, label: string, sound: boolean) {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Starting timer…" });
  const ok = await withErrorToast(() => startTimer({ duration, label, sound }));
  if (ok !== undefined) {
    toast.style = Toast.Style.Success;
    toast.title = label ? `${label} started` : "Timer started";
    toast.message = `${Math.round(duration / 60)}m on Pulse`;
  }
}

export default function StartTimer() {
  const { push } = useNavigation();

  return (
    <List searchBarPlaceholder="Pick a preset or create custom…">
      <List.Section title="Presets">
        {PRESETS.map((p) => (
          <List.Item
            key={p.title}
            icon={p.icon}
            title={p.title}
            subtitle={p.subtitle}
            actions={
              <ActionPanel>
                <Action
                  title={`Start ${p.subtitle}`}
                  onAction={() => launch(p.duration, p.title, true)}
                />
                <Action
                  title="Customize…"
                  icon={Icon.Pencil}
                  onAction={() => push(<CustomTimerForm defaultLabel={p.title} defaultMinutes={p.duration / 60} />)}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>

      <List.Section title="Custom">
        <List.Item
          icon={Icon.Clock}
          title="Custom Timer"
          subtitle="Set your own duration"
          actions={
            <ActionPanel>
              <Action title="Set Duration" onAction={() => push(<CustomTimerForm />)} />
            </ActionPanel>
          }
        />
      </List.Section>
    </List>
  );
}

function CustomTimerForm({
  defaultLabel = "",
  defaultMinutes = 25,
}: {
  defaultLabel?: string;
  defaultMinutes?: number;
}) {
  const { pop } = useNavigation();
  const [minutes, setMinutes] = useState(String(defaultMinutes));
  const [seconds, setSeconds] = useState("0");
  const [label, setLabel] = useState(defaultLabel);
  const [sound, setSound] = useState(true);
  const [minuteError, setMinuteError] = useState<string | undefined>();

  function validate() {
    const m = parseInt(minutes, 10);
    const s = parseInt(seconds, 10);
    if (isNaN(m) || m < 0 || m > 999) {
      setMinuteError("Enter 0–999");
      return null;
    }
    setMinuteError(undefined);
    const total = m * 60 + (isNaN(s) ? 0 : s);
    if (total <= 0) {
      setMinuteError("Duration must be > 0");
      return null;
    }
    return total;
  }

  async function handleSubmit() {
    const total = validate();
    if (total == null) return;
    await launch(total, label, sound);
    pop();
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Start Timer" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextField
        id="minutes"
        title="Minutes"
        value={minutes}
        onChange={setMinutes}
        error={minuteError}
        placeholder="25"
      />
      <Form.TextField
        id="seconds"
        title="Seconds"
        value={seconds}
        onChange={setSeconds}
        placeholder="0"
      />
      <Form.TextField
        id="label"
        title="Label"
        value={label}
        onChange={setLabel}
        placeholder="Focus (optional)"
      />
      <Form.Checkbox id="sound" label="Vibrate on completion" value={sound} onChange={setSound} />
    </Form>
  );
}
