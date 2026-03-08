package cmd

import (
	"fmt"
	"time"

	"github.com/shubham030/pulse/cli/internal/client"
	"github.com/spf13/cobra"
)

var queueHost string

var queueCmd = &cobra.Command{
	Use:   "queue",
	Short: "Manage the timer queue",
	Long:  "Add, list, or clear timers in the queue. Queued timers run sequentially.",
}

var (
	queueAddLabel   string
	queueAddNoSound bool
)

var queueAddCmd = &cobra.Command{
	Use:   "add <duration>",
	Short: "Add a timer to the queue",
	Args:  cobra.ExactArgs(1),
	Example: `  pulse queue add 25m --label Focus
  pulse queue add 5m --label "Short Break"`,
	RunE: func(cmd *cobra.Command, args []string) error {
		d, err := time.ParseDuration(args[0])
		if err != nil {
			return fmt.Errorf("invalid duration %q: use Go duration format e.g. 25m, 1h30m", args[0])
		}
		if d <= 0 {
			return fmt.Errorf("duration must be positive")
		}

		host, port, err := resolveHost(queueHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Enqueue(client.TimerRequest{
			Duration: int(d.Seconds()),
			Label:    queueAddLabel,
			Sound:    !queueAddNoSound,
		}); err != nil {
			return fmt.Errorf("failed to enqueue: %w", err)
		}

		label := args[0]
		if queueAddLabel != "" {
			label = fmt.Sprintf("%s (%s)", queueAddLabel, args[0])
		}
		fmt.Printf("  Queued: %s\n", label)
		return nil
	},
}

var queueListCmd = &cobra.Command{
	Use:   "list",
	Short: "Show the timer queue",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(queueHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		s, err := c.Status()
		if err != nil {
			return fmt.Errorf("failed to get status: %w", err)
		}

		if len(s.Queue) == 0 {
			fmt.Println("  Queue is empty.")
			return nil
		}

		fmt.Printf("  %d timer(s) in queue:\n", len(s.Queue))
		for i, q := range s.Queue {
			label := q.Label
			if label == "" {
				label = "Timer"
			}
			fmt.Printf("    %d. %s — %s\n", i+1, label, client.FormatDuration(q.Duration))
		}
		return nil
	},
}

var queueClearCmd = &cobra.Command{
	Use:   "clear",
	Short: "Clear the timer queue",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(queueHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.ClearQueue(); err != nil {
			return fmt.Errorf("failed to clear queue: %w", err)
		}

		fmt.Printf("  Queue cleared on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	queueCmd.PersistentFlags().StringVar(&queueHost, "host", "", "Phone IP address")

	queueAddCmd.Flags().StringVar(&queueAddLabel, "label", "", "Timer label")
	queueAddCmd.Flags().BoolVar(&queueAddNoSound, "no-sound", false, "Disable vibration")

	queueCmd.AddCommand(queueAddCmd)
	queueCmd.AddCommand(queueListCmd)
	queueCmd.AddCommand(queueClearCmd)
}
