package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "pulse",
	Short: "Control the Pulse remote timer display",
	Long: `Pulse CLI — control your Pulse timer display from the terminal.

Auto-discovers devices via mDNS, or use --host to specify manually.
Configuration cached at ~/.config/pulse/config.json.`,
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(stopCmd)
	rootCmd.AddCommand(pauseCmd)
	rootCmd.AddCommand(resumeCmd)
	rootCmd.AddCommand(skipCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(queueCmd)
	rootCmd.AddCommand(pomodoroCmd)
	rootCmd.AddCommand(themeCmd)
	rootCmd.AddCommand(discoverCmd)
}
