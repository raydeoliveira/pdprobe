---
name: pdprobe
description: >-
  Audits USB-C Power Delivery Objects (PDOs) with bottleneck diagnostics, reads live
  VBUS/IBUS/Power/CC/D+/D-/Temp telemetry with session summaries, and triggers PD/PPS/EPR-AVS
  voltages with safe-5V rollback across Apple Silicon IOKit (read-only), Linux
  sysfs/hidraw/usbfs, Power-Z KM003C, and FNIRSI FNB58. Exposes --describe, --json
  envelopes, --from-json - UNIX pipes, --sim/--fixture modes, and a stdio JSON-RPC 2.0 MCP server.
---

# Skill: pdprobe (`pdctl`)

## Install & Discovery
```bash
brew tap raydeoliveira/tap && brew install pdprobe
# Or build from source (pdprobe-src):
make release
# Discover CLI + MCP capabilities in one call:
pdprobe --describe
pdprobe --version --json
pdprobe --help
```

`pdctl` is a symlink alias for `pdprobe`.

## Free Core vs. Commercial Pro Boundary
- **Free Core**: `probe`, `audit` (with `diagnostics` bottleneck analysis), `telemetry` (with `summary` min/avg/max/mWh), `reset`, `--dry-run`, `--describe`, `--version`, `--help`, read-only/`dry_run: true` MCP tools, and interactive TTY fixed SPR live triggers (`5V–20V`, `<=100W`, no `--yes`/`--from-json`).
- **Pro ($29 one-time)**: Programmable PPS (`20 mV` stepping) & EPR-AVS (`>20V` / `<=240W`) live triggers, unattended `--yes` / `--from-json -` scripting, and live MCP `trigger_pd_pps` calls (`dry_run: false`). Exit `5` hints include the Polar.sh checkout URL (`https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz`).
- **`-DOSS_EDITION`**: Source build unlocks all triggers offline with no license checks.

## Safe Read-Only & Trigger Workflow

1. **Probe attached host ports and testers** (Free Core, read-only):
   ```bash
   pdprobe probe --json
   pdprobe probe --sim --json
   ```
2. **Audit source PDOs, active contracts, and cable/source bottlenecks** (Free Core, read-only):
   ```bash
   pdprobe audit --device host --json
   pdprobe audit --device host --port port0 --include-serial --json
   pdprobe audit --device km003c --sim --json
   ```
3. **Read bounded or streaming telemetry with session summary** (Free Core, read-only):
   ```bash
   pdprobe telemetry --device fnb58 --sim --count 4 --json
   pdprobe telemetry --device km003c --sim --stream --count 5 --interval-ms 100
   ```
4. **Preview a PD/PPS trigger before touching hardware** (Free Core, zero hardware writes):
   ```bash
   pdprobe trigger --device km003c --sim --voltage-mv 9000 --mode pps --dry-run --json
   ```
5. **Apply a live trigger with snapshot and 5V auto-revert** (Interactive fixed SPR `5–20V` is Free Core; PPS/EPR or non-TTY `--yes` requires Pro or `-DOSS_EDITION`):
   ```bash
   # Interactive fixed SPR (Free Core):
   pdprobe trigger --device km003c --voltage-mv 9000 --mode fixed

   # Scripted PPS / EPR-AVS (Pro or -DOSS_EDITION):
   pdprobe trigger --device km003c --voltage-mv 9000 --current-ma 3000 --mode pps --confirm-timeout 15 --yes --json
   ```
   - Safety cap: defaults to `<= 20000 mV` and `<= 100000 mW`; pass `--allow-epr` to unlock >20V / >100W EPR.
   - FNIRSI FNB58 triggering (`0x85`/`0x86`) is experimental and requires `--experimental`.
6. **Revert active trigger to safe 5V** (always Free Core):
   ```bash
   pdprobe reset --device km003c --dry-run --json
   pdprobe reset --device km003c --yes --json
   ```

## UNIX Composability (`--from-json -`)

Pipe an upstream `audit --json` envelope directly into `trigger` (`ok: false` fails closed with exit `2`; explicit CLI flags override piped JSON):
```bash
pdprobe audit --device km003c --sim --json \
  | pdprobe trigger --from-json - --device km003c --sim --voltage-mv 9000 --dry-run --json
```

## Subcommands (All 7)
- `probe`: Discover host USB-C ports and connected PD testers (`--fixture`, `--sim`, `--json`).
- `audit`: Audit source PDOs, active contracts, and `diagnostics` bottlenecks (`--device host|km003c|fnb58|auto`, `--port`, `--include-serial`, `--fixture`, `--sim`, `--json`).
- `telemetry`: Read live or fixture VBUS/IBUS/Power/D+/D-/CC/Temp samples + `summary` (`--device`, `--stream`, `--count`, `--interval-ms`, `--fixture`, `--sim`, `--json`).
- `trigger`: Negotiate PD/PPS/EPR-AVS voltage/current with `lstat` snapshot and safe-5V rollback (`--voltage-mv`, `--current-ma`, `--mode fixed|pps|spr-avs|epr-avs|auto`, `--pdo-index 1..15`, `--confirm-timeout`, `--allow-epr`, `--experimental`, `--dry-run`, `--yes`, `--from-json`, `--fixture`, `--sim`, `--json`).
- `reset`: Revert active trigger to safe 5V (always Free Core; `--device`, `--dry-run`, `--yes`, `--fixture`, `--sim`, `--json`).
- `license`: Manage Polar.sh license (`activate|status|deactivate`, `--key`, `--force-local`, `--json`; falls back to `PDPROBE_LICENSE_KEY`).
- `mcp`: Run newline-delimited stdio JSON-RPC 2.0 MCP server (`protocolVersion: "2024-11-05"`).

## Native MCP Server (`pdprobe mcp`)

`pdprobe mcp` implements `initialize`, `ping`, `tools/list`, and `tools/call` (notifications without `"id"` produce zero stdout bytes). Mutating tools default to `dry_run: true` and `yes: false`.

| Tool | Role | Default Safety / Notes |
|---|---|---|
| `list_pd_profiles` | List supported devices, voltage/power caps, and honest limits | Read-only (`{}`) |
| `probe_pd_devices` | Discover host USB-C ports and connected testers | Read-only (`fixture?`, `sim?`) |
| `audit_pdos` | Audit source PDOs, active contracts, and `diagnostics` | Read-only (`device?`, `port?`, `include_serial?`, `fixture?`, `sim?`) |
| `read_pd_telemetry` | Read bounded `1..1024` telemetry samples with `summary` | Read-only (`device?`, `count?`, `fixture?`, `sim?`) |
| `trigger_pd_pps` | Negotiate PD/PPS/EPR-AVS voltage with safety caps | `dry_run: true`, `yes: false`, `allow_epr: false`, `experimental: false`; live MCP write (`dry_run: false`) requires Pro or `-DOSS_EDITION` |
| `reset_pd_safe5v` | Revert active PD/PPS trigger to safe 5V | `dry_run: true`, `yes: false`; always Free Core |

## Exit Codes
- `0`: Success
- `1`: Runtime / I/O / rollback / telemetry readback failure
- `2`: Usage / validation / PDO out-of-range / missing `--yes` in non-TTY / unknown flag or key
- `3`: Hardware or capability unavailable (no device, Apple Silicon/Linux host trigger unsupported, FNB58 PDO table unsupported)
- `4`: Permission / entitlement / `lstat` symlink check / kernel driver busy (on Linux, install `99-pdprobe.rules`)
- `5`: Commercial Pro license missing, invalid, or expired (PPS/EPR, scripted `--yes`/`--from-json`, or live MCP `trigger_pd_pps`; never in `-DOSS_EDITION`, `--dry-run`, interactive fixed SPR `5–20V`, `probe`, `audit`, `telemetry`, or `reset`)
- `130`: Interrupted (`SIGINT` / `SIGTERM`) after clean safe-5V rollback

## Environment & Honest Hardware Limits
- **Host Ports (`host`)**: Apple Silicon `IOKit` (`Mac16,6` verified) and Linux `sysfs` are strictly read-only (`trigger` / `reset` exit `3`). `SerialString` is redacted unless `--include-serial` is passed.
- **FNIRSI FNB58 (`fnb58`)**: Supports `0x04` 64-byte HID CRC-8 telemetry and `--experimental` `0x85`/`0x86` trigger; does not expose Source PDO tables (`audit` exits `3`).
- **Simulation & Fixtures**: `--sim` and `--fixture <path>` auto-detect `{`-prefixed JSON scenarios, 64B `0xAA` FNB58 HID binary dumps, and `0x41` KM003C `PutData` binary dumps.
- **State Paths**: License cache `$XDG_CONFIG_HOME/pdprobe/license.json` (`0600`), snapshots `$XDG_STATE_HOME/pdprobe/snapshot.json` (`0600`, `lstat`-guarded), env vars `PDPROBE_LICENSE_KEY`, `PDPROBE_POLAR_API_URL`.
