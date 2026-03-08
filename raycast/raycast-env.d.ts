/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** Phone IP Address - IP address of your Android phone running Pulse */
  "host": string,
  /** Port - Port the Pulse server listens on */
  "port": string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `start-timer` command */
  export type StartTimer = ExtensionPreferences & {}
  /** Preferences accessible in the `stop-timer` command */
  export type StopTimer = ExtensionPreferences & {}
  /** Preferences accessible in the `timer-status` command */
  export type TimerStatus = ExtensionPreferences & {}
  /** Preferences accessible in the `pause-timer` command */
  export type PauseTimer = ExtensionPreferences & {}
  /** Preferences accessible in the `resume-timer` command */
  export type ResumeTimer = ExtensionPreferences & {}
  /** Preferences accessible in the `start-pomodoro` command */
  export type StartPomodoro = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `start-timer` command */
  export type StartTimer = {}
  /** Arguments passed to the `stop-timer` command */
  export type StopTimer = {}
  /** Arguments passed to the `timer-status` command */
  export type TimerStatus = {}
  /** Arguments passed to the `pause-timer` command */
  export type PauseTimer = {}
  /** Arguments passed to the `resume-timer` command */
  export type ResumeTimer = {}
  /** Arguments passed to the `start-pomodoro` command */
  export type StartPomodoro = {}
}

