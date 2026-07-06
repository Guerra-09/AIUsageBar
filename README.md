# ClaudeUsageBar

Menu bar app (macOS) that shows your current [Claude Code](https://claude.com/claude-code) usage: session % (5h window) and weekly %, with time until each resets.

Reads local usage data via [ccusage](https://github.com/ccusage/ccusage) — no network calls, no auth, no scraping of claude.ai.

## Requirements

- macOS 14+
- [ccusage](https://github.com/ccusage/ccusage) installed and on `PATH`:
  ```
  npm install -g ccusage
  ```

## Build & run

```
swift build -c release
```

Then package as an app bundle (or just run the built binary directly):

```bash
APP=ClaudeUsageBar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ClaudeUsageBar "$APP/Contents/MacOS/ClaudeUsageBar"
cp Info.plist "$APP/Contents/Info.plist"
open "$APP"
```

## Calibrating the percentages

Anthropic doesn't publish an exact token quota for Claude Code — the % shown in the Claude.ai UI is computed server-side and isn't exposed via any public API. This app estimates it from raw token counts (via `ccusage`) against a configurable limit.

To calibrate:
1. Open Claude.ai and note your real session % and weekly %.
2. Open the app's ⚙️ settings.
3. Adjust "Límite tokens sesión" / "Límite tokens semana" until the app's % matches what you saw.
4. Set your actual weekly reset weekday.

These estimates can drift over time (the token mix between fresh input and cache reads varies per session), so re-calibrate occasionally.

## License

MIT
