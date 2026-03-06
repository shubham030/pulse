# Contributing to Pulse

Thanks for your interest in contributing! Pulse is a simple project and we want to keep contributions straightforward.

## Getting Started

1. Fork the repo and clone your fork
2. Pick what you want to work on:
   - **Flutter app** — `cd app && flutter pub get && flutter run`
   - **CLI** — `cd cli && go build -o pulse .`
   - **Raycast extension** — `cd raycast && npm install && npm run dev`

## Project Structure

```
pulse/
  app/              Flutter app (Android/iOS)
    lib/
      providers/    Riverpod state management
      screens/      UI screens
      services/     HTTP server, foreground service, mDNS, device discovery
      theme/        Theme definitions
      widgets/      Reusable widgets
  cli/              Go CLI tool
    cmd/            Cobra commands
    internal/       Client, mDNS discovery, config
  raycast/          Raycast extension (TypeScript)
    src/            Commands and API client
```

## Development

### Flutter App

- Requires Flutter SDK (stable channel)
- State management: Riverpod 3 with `Notifier`
- HTTP server runs in a foreground service isolate via `shelf`
- Test on a real Android device for foreground service and mDNS

### CLI

- Requires Go 1.25+
- Uses Cobra for commands, `zeroconf` for mDNS discovery
- Auto-discovers devices; caches config at `~/.config/pulse/config.json`

### Raycast Extension

- Requires Node.js and Raycast installed
- `npm run dev` to develop, `npm run build` to build

## Making Changes

1. Create a branch from `main`: `git checkout -b feat/your-feature`
2. Make your changes
3. Run the relevant checks:
   - Flutter: `cd app && flutter analyze`
   - Go: `cd cli && go vet ./...`
   - Raycast: `cd raycast && npm run lint`
4. Test on a real device if touching app code
5. Open a PR

## Commit Style

We use [conventional commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code restructuring
- `docs:` — documentation
- `chore:` — build, deps, tooling

Keep the subject under 72 characters, imperative mood.

## Pull Requests

- Short title, conventional commit style
- Brief description of what changed and why
- Note how you tested it

## Ideas for Contributions

Here are some things that would be great to add:

- **iOS support** — test and fix any iOS-specific issues
- **Audio alerts** — play a sound on timer completion (currently vibration only)
- **Custom presets** — let users create/edit/reorder preset cards
- **Home screen widget** — Android widget showing timer status
- **Apple Watch / Wear OS** — companion app for wrist
- **Siri/Shortcuts integration** — start timers from iOS Shortcuts
- **Ambient clock mode** — show a minimal clock when idle
- **More themes** — design and add new color themes
- **Localization** — translate the app
- **Tests** — unit tests for providers, widget tests for screens

## Reporting Issues

Open an issue with:
- What you expected vs what happened
- Device/OS info
- Steps to reproduce

## Code of Conduct

Be kind, be constructive. We're all here to build something useful.
