package mdns

import (
	"context"
	"time"

	"github.com/grandcat/zeroconf"
)

type Device struct {
	Name string
	Host string
	Port int
}

// Discover browses for _pulse._tcp services and returns found devices.
func Discover(ctx context.Context, timeout time.Duration) ([]Device, error) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		return nil, err
	}

	entries := make(chan *zeroconf.ServiceEntry)
	var devices []Device

	browseCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	if err := resolver.Browse(browseCtx, "_pulse._tcp", "local.", entries); err != nil {
		return nil, err
	}

	for {
		select {
		case entry, ok := <-entries:
			if !ok {
				return devices, nil
			}
			host := entry.HostName
			if len(entry.AddrIPv4) > 0 {
				host = entry.AddrIPv4[0].String()
			}
			devices = append(devices, Device{
				Name: entry.Instance,
				Host: host,
				Port: entry.Port,
			})
		case <-browseCtx.Done():
			return devices, nil
		}
	}
}
