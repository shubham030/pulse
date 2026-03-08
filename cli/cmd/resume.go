package cmd

import (
	"fmt"

	"github.com/shubham030/pulse/cli/internal/client"
	"github.com/spf13/cobra"
)

var resumeHost string

var resumeCmd = &cobra.Command{
	Use:   "resume",
	Short: "Resume a paused timer",
	RunE: func(cmd *cobra.Command, args []string) error {
		host, port, err := resolveHost(resumeHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Resume(); err != nil {
			return fmt.Errorf("failed to resume: %w", err)
		}

		fmt.Printf("  Timer resumed on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	resumeCmd.Flags().StringVar(&resumeHost, "host", "", "Phone IP address")
}
