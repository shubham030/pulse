package cmd

import (
	"fmt"

	"github.com/shubham030/pulse-cli/internal/client"
	"github.com/spf13/cobra"
)

var (
	pomodoroHost       string
	pomodoroFocus      int
	pomodoroShortBreak int
	pomodoroLongBreak  int
	pomoroCycles       int
)

var pomodoroCmd = &cobra.Command{
	Use:   "pomodoro",
	Short: "Start a pomodoro session",
	Example: `  pulse pomodoro
  pulse pomodoro --focus 30 --short-break 5 --cycles 6`,
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(pomodoroHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		cfg := client.PomodoroConfig{
			FocusMinutes:          pomodoroFocus,
			ShortBreakMinutes:     pomodoroShortBreak,
			LongBreakMinutes:      pomodoroLongBreak,
			CyclesBeforeLongBreak: pomoroCycles,
			TotalCycles:           pomoroCycles,
		}
		if err := c.StartPomodoro(cfg); err != nil {
			return fmt.Errorf("failed to start pomodoro: %w", err)
		}

		fmt.Printf("  Pomodoro started on %s:%d\n", host, port)
		fmt.Printf("  %dm focus / %dm break x %d cycles\n",
			pomodoroFocus, pomodoroShortBreak, pomoroCycles)
		return nil
	},
}

func init() {
	pomodoroCmd.Flags().StringVar(&pomodoroHost, "host", "", "Phone IP address")
	pomodoroCmd.Flags().IntVar(&pomodoroFocus, "focus", 25, "Focus duration in minutes")
	pomodoroCmd.Flags().IntVar(&pomodoroShortBreak, "short-break", 5, "Short break in minutes")
	pomodoroCmd.Flags().IntVar(&pomodoroLongBreak, "long-break", 15, "Long break in minutes")
	pomodoroCmd.Flags().IntVar(&pomoroCycles, "cycles", 4, "Number of cycles")
}
