package cmd

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"
	"github.com/shubham030/pulse-cli/internal/client"
	"github.com/shubham030/pulse-cli/internal/config"
	"github.com/shubham030/pulse-cli/internal/mdns"
)

var (
	startLabel   string
	startHost    string
	startNoSound bool
)

var startCmd = &cobra.Command{
	Use:   "start <duration>",
	Short: "Start a timer on the Pulse display",
	Args:  cobra.ExactArgs(1),
	Example: `  pulse start 25m
  pulse start 1h30m --label "Deep Work"
  pulse start 5m --host 192.168.1.42`,
	RunE: func(cmd *cobra.Command, args []string) error {
		d, err := time.ParseDuration(args[0])
		if err != nil {
			return fmt.Errorf("invalid duration %q: use Go duration format e.g. 25m, 1h30m", args[0])
		}
		if d <= 0 {
			return fmt.Errorf("duration must be positive")
		}

		host, port, err := resolveHost(startHost)
		if err != nil {
			return err
		}

		c := client.New(host, port)
		if err := c.Start(client.TimerRequest{
			Duration: int(d.Seconds()),
			Label:    startLabel,
			Sound:    !startNoSound,
		}); err != nil {
			return fmt.Errorf("failed to start timer: %w", err)
		}

		label := args[0]
		if startLabel != "" {
			label = fmt.Sprintf("%s (%s)", startLabel, args[0])
		}
		fmt.Printf("Timer started: %s on %s:%d\n", label, host, port)
		return nil
	},
}

// resolveHost returns (host, port) from flag > config cache > mDNS discovery.
func resolveHost(flagHost string) (string, int, error) {
	if flagHost != "" {
		return flagHost, 7878, nil
	}

	cfg, err := config.Load()
	if err == nil && cfg.Host != "" {
		return cfg.Host, cfg.Port, nil
	}

	fmt.Println("No host configured; discovering via mDNS...")
	devices, err := mdns.Discover(context.Background(), 3*time.Second)
	if err != nil || len(devices) == 0 {
		return "", 0, fmt.Errorf("no Pulse device found; use --host or run 'pulse discover'")
	}

	d := devices[0]
	_ = config.Save(&config.Config{Host: d.Host, Port: d.Port})
	fmt.Printf("Found: %s (%s:%d) — cached for next time\n", d.Name, d.Host, d.Port)
	return d.Host, d.Port, nil
}

func init() {
	startCmd.Flags().StringVar(&startLabel, "label", "", "Timer label (e.g. \"Focus\")")
	startCmd.Flags().StringVar(&startHost, "host", "", "Phone IP address (overrides discovery)")
	startCmd.Flags().BoolVar(&startNoSound, "no-sound", false, "Disable vibration on completion")
}
