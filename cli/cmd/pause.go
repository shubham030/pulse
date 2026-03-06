package cmd

import (
	"fmt"

	"github.com/shubham030/pulse-cli/internal/client"
	"github.com/spf13/cobra"
)

var pauseHost string

var pauseCmd = &cobra.Command{
	Use:   "pause",
	Short: "Pause the running timer",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(pauseHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Pause(); err != nil {
			return fmt.Errorf("failed to pause: %w", err)
		}

		fmt.Printf("  Timer paused on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	pauseCmd.Flags().StringVar(&pauseHost, "host", "", "Phone IP address")
}
