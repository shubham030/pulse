# Privacy Policy

**Last updated:** March 7, 2026

## Overview

Pulse is an open-source, offline timer application. Your privacy is simple: we don't collect anything.

## Data Collection

Pulse does **not** collect, store, or transmit any personal data. Specifically:

- No analytics or tracking
- No user accounts or authentication
- No data sent to external servers
- No crash reporting to third parties
- No advertising SDKs

## Local Network Communication

Pulse runs an HTTP server on your local network (port 7878) to enable remote control from other devices. This communication stays entirely within your local network and is not routed through any external service.

Pulse uses mDNS (Bonjour) to advertise itself on your local network for device discovery. This is a standard local network protocol and does not involve any internet communication.

## Permissions

- **Foreground service:** Used to keep the timer running while the screen is on.
- **Vibration:** Used to alert when a timer completes.

## Contact

If you have questions about this privacy policy, open an issue at [github.com/shubham030/pulse](https://github.com/shubham030/pulse/issues).
