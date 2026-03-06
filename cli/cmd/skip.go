package cmd

import (
	"fmt"

	"github.com/shubham030/pulse-cli/internal/client"
	"github.com/spf13/cobra"
)

var skipHost string

var skipCmd = &cobra.Command{
	Use:   "skip",
	Short: "Skip to the next timer in queue or pomodoro",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(skipHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Skip(); err != nil {
			return fmt.Errorf("failed to skip: %w", err)
		}

		fmt.Printf("  Skipped to next on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	skipCmd.Flags().StringVar(&skipHost, "host", "", "Phone IP address")
}
