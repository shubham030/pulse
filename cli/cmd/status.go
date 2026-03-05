package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/shubham030/pulse-cli/internal/client"
)

var statusHost string

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

		if !s.Running {
			fmt.Println("No timer running.")
			return nil
		}

		minutes := s.Remaining / 60
		seconds := s.Remaining % 60
		label := s.Label
		if label == "" {
			label = "Timer"
		}
		fmt.Printf("%s — %02d:%02d remaining\n", label, minutes, seconds)
		return nil
	},
}

func init() {
	statusCmd.Flags().StringVar(&statusHost, "host", "", "Phone IP address")
}
