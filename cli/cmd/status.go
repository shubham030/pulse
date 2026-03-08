package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/shubham030/pulse/cli/internal/client"
	"github.com/spf13/cobra"
)

var (
	statusHost string
	statusJSON bool
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show current timer status",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(statusHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		s, err := c.Status()
		if err != nil {
			return fmt.Errorf("failed to get status: %w", err)
		}

		if statusJSON {
			enc := json.NewEncoder(os.Stdout)
			enc.SetIndent("", "  ")
			return enc.Encode(s)
		}

		if s.Status == "idle" {
			fmt.Println("  No timer running.")
			return nil
		}

		label := s.Label
		if label == "" {
			label = "Timer"
		}
		time := client.FormatDuration(s.Remaining)

		var state string
		switch s.Status {
		case "paused":
			state = " (paused)"
		case "completed":
			state = " (completed)"
		}

		fmt.Printf("  %s — %s remaining%s\n", label, time, state)

		if s.Total > 0 {
			progress := 1.0 - float64(s.Remaining)/float64(s.Total)
			bar := renderProgressBar(progress, 30)
			fmt.Printf("  %s %.0f%%\n", bar, progress*100)
		}

		if s.Pomodoro != nil {
			p := s.Pomodoro
			fmt.Printf("  Pomodoro: %s %d/%d | %dm focus / %dm break\n",
				strings.Title(p.Phase), p.CurrentCycle, p.TotalCycles,
				p.Config.FocusMinutes, p.Config.ShortBreakMinutes)
		}

		if len(s.Queue) > 0 {
			fmt.Printf("  Queue: %d timers\n", len(s.Queue))
			for i, q := range s.Queue {
				ql := q.Label
				if ql == "" {
					ql = "Timer"
				}
				fmt.Printf("    %d. %s (%s)\n", i+1, ql, client.FormatDuration(q.Duration))
			}
		}

		return nil
	},
}

func renderProgressBar(progress float64, width int) string {
	filled := int(progress * float64(width))
	if filled > width {
		filled = width
	}
	empty := width - filled
	return "[" + strings.Repeat("█", filled) + strings.Repeat("░", empty) + "]"
}

func init() {
	statusCmd.Flags().StringVar(&statusHost, "host", "", "Phone IP address")
	statusCmd.Flags().BoolVar(&statusJSON, "json", false, "Output as JSON")
}
