package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/shubham030/pulse/cli/internal/client"
)

var stopHost string

var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop the running timer",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(stopHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Stop(); err != nil {
			return fmt.Errorf("failed to stop timer: %w", err)
		}

		fmt.Printf("Timer stopped on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	stopCmd.Flags().StringVar(&stopHost, "host", "", "Phone IP address")
}
