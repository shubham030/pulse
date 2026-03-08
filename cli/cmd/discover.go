package cmd

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"
	"github.com/shubham030/pulse/cli/internal/mdns"
)

var discoverTimeout time.Duration

var discoverCmd = &cobra.Command{
	Use:   "discover",
	Short: "Find Pulse devices on the local network",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Printf("Scanning for Pulse devices (timeout: %s)...\n", discoverTimeout)
		devices, err := mdns.Discover(context.Background(), discoverTimeout)
		if err != nil {
			return fmt.Errorf("discovery failed: %w", err)
		}

		if len(devices) == 0 {
			fmt.Println("No Pulse devices found.")
			return nil
		}

		for _, d := range devices {
			fmt.Printf("  %s  %s:%d\n", d.Name, d.Host, d.Port)
		}
		return nil
	},
}

func init() {
	discoverCmd.Flags().DurationVar(&discoverTimeout, "timeout", 5*time.Second, "Discovery timeout")
}
