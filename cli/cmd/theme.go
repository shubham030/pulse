package cmd

import (
	"fmt"

	"github.com/shubham030/pulse/cli/internal/client"
	"github.com/spf13/cobra"
)

var themeHost string

var validThemes = []string{"dark", "ambient", "warm", "forest", "ocean", "rose"}

var themeCmd = &cobra.Command{
	Use:       "theme <name>",
	Short:     "Set the display theme",
	Args:      cobra.ExactArgs(1),
	ValidArgs: validThemes,
	Example:   "  pulse theme ambient\n  pulse theme forest",
	RunE: func(cmd *cobra.Command, args []string) error {
		theme := args[0]
		valid := false
		for _, t := range validThemes {
			if t == theme {
				valid = true
				break
			}
		}
		if !valid {
			return fmt.Errorf("unknown theme %q; valid themes: %v", theme, validThemes)
		}

		host, port, err := resolveHost(themeHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.SetTheme(theme); err != nil {
			return fmt.Errorf("failed to set theme: %w", err)
		}

		fmt.Printf("  Theme set to '%s' on %s:%d\n", theme, host, port)
		return nil
	},
}

func init() {
	themeCmd.Flags().StringVar(&themeHost, "host", "", "Phone IP address")
}
