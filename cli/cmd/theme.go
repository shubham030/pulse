package cmd

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/spf13/cobra"
)

var themeHost string

var themeCmd = &cobra.Command{
	Use:       "theme [dark|ambient]",
	Short:     "Set the display theme",
	Args:      cobra.ExactArgs(1),
	ValidArgs: []string{"dark", "ambient"},
	RunE: func(cmd *cobra.Command, args []string) error {
		theme := args[0]
		if theme != "dark" && theme != "ambient" {
			return fmt.Errorf("theme must be 'dark' or 'ambient'")
		}

		host, port, err := resolveHost(themeHost)
		if err != nil {
			return err
		}

		body, _ := json.Marshal(map[string]string{"theme": theme})
		resp, err := http.Post(
			fmt.Sprintf("http://%s:%d/settings", host, port),
			"application/json",
			bytes.NewReader(body),
		)
		if err != nil {
			return fmt.Errorf("request failed: %w", err)
		}
		defer resp.Body.Close()

		fmt.Printf("Theme set to '%s' on %s:%d\n", theme, host, port)
		return nil
	},
}

func init() {
	themeCmd.Flags().StringVar(&themeHost, "host", "", "Phone IP address")
}
