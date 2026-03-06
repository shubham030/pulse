export type TimerRequest = {
  duration: number; // seconds
  label: string;
  sound: boolean;
};

export type QueuedTimer = {
  duration: number;
  label: string;
  sound: boolean;
};

export type PomodoroConfig = {
  focusMinutes?: number;
  shortBreakMinutes?: number;
  longBreakMinutes?: number;
  cyclesBeforeLongBreak?: number;
  totalCycles?: number;
};

export type PomodoroState = {
  config: PomodoroConfig;
  currentCycle: number;
  totalCycles: number;
  phase: "focus" | "shortBreak" | "longBreak";
};

export type StatusResponse = {
  status: "idle" | "running" | "paused" | "completed";
  running: boolean;
  paused: boolean;
  remaining: number;
  total: number;
  label: string;
  queue: QueuedTimer[];
  pomodoro?: PomodoroState;
};

export type OkResponse = {
  ok: boolean;
  error?: string;
};
