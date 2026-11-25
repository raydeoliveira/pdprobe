# Polar.sh Product Listing — pdprobe Pro (macOS & Linux)

> Enable Polar's built-in **License Keys** benefit (prefix: `PDPROBE`, activation limit: `3` machines per buyer, expiration: never / perpetual).

---

## Product Title
**pdprobe Pro — macOS & Linux USB-C PDO Auditor, Telemetry Reader & PD/PPS Trigger CLI + MCP Server**

## Price & Billing Model
- **$29 USD** — One-time purchase ([Polar Checkout](https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz), Perpetual License, v0.x updates included, up to 3 personal machines).
- **Generous Free Core Tier** included in the same **217,264-byte (~212 KB)** stripped macOS `arm64` binary (`probe`, `audit` with charger/cable bottleneck diagnostics, `telemetry` with session min/avg/max/mWh summary, `reset`, `--dry-run`, `--describe`, read-only/`dry_run: true` MCP tools, AND interactive fixed SPR `5V–20V` live triggers).
- **Open-Source Compile Seam**: Building from source with `-DOSS_EDITION` (`make release OSS_EDITION=1`) unlocks all features offline with zero license checks.

## Summary
Replace Windows-only vendor tools for Power-Z KM003C, FNIRSI FNB58, and Apple Silicon USB-C ports with a single zero-dependency C17 CLI (`pdprobe` / `pdctl`), static library (`libpdprobe.a`), and local stdio MCP server (`2024-11-05`). Diagnose MacBook charger/cable bottlenecks with no dongle attached, stream VBUS/IBUS/Power/CC/D+/D-/Temp telemetry, and trigger PD/PPS/EPR-AVS voltages with atomic snapshots and automatic 5V rollback.

## Activation & Cache Storage
```bash
export PDPROBE_LICENSE_KEY="PDPROBE-XXXX-XXXX-XXXX"
pdprobe license activate --json
```
Validated license metadata (14-day offline grace period) is stored with `0600` permissions and `lstat` symlink checks at:
- `$XDG_CONFIG_HOME/pdprobe/license.json`, or
- `~/.config/pdprobe/license.json`, or
- `$XDG_STATE_HOME/pdprobe/license.json`.

## Free Core vs. Pro Comparison (`v0.2.0`)

| Feature | Free Core | Pro ($29 one-time) |
|---|---|---|
| `probe` (Apple Silicon IOKit, Linux sysfs, KM003C, FNB58, `--sim`, `--fixture`) | Included | Included |
| `audit` (USB-PD 3.0/3.1/3.2 PDO/RDO decoding, bottleneck `diagnostics`, `--include-serial`) | Included | Included |
| `telemetry` (`--stream` JSONL, 1024-slot O(1) ring buffer, min/avg/max/mWh `summary`) | Included | Included |
| `reset` (emergency revert to safe 5V, CLI & `reset_pd_safe5v` MCP) | Included | Included |
| `trigger --dry-run` (PDO validation & RDO calculation without writes) | Included | Included |
| Interactive fixed SPR live triggers (`5V–20V`, `<=100W`, TTY confirm + 5V rollback) | Included | Included |
| `pdprobe mcp` read-only tools & `trigger_pd_pps` with `dry_run: true` | Included | Included |
| Programmable **PPS (`20 mV`)** & **EPR-AVS (`>20V`, up to `48V / 240W`)** triggers | — | Included |
| Unattended / scripted trigger automation (`--yes`, `--from-json -`) | — | Included |
| Live AI-agent MCP hardware writes (`trigger_pd_pps` with `dry_run: false`) | — | Included |

## Requirements & Honest Limits
- **OS & Architecture**: macOS 14+ (`arm64` / `x86_64` via `IOKit` + `CoreFoundation`) and Linux (`sysfs`, `hidraw`, `usbfs`, `/dev/ttyACM*`).
- **Read-Only Host Ports**: Apple Silicon `IOKit` and Linux `sysfs` host ports are strictly read-only (`trigger` and `reset` exit `3`).
- **FNIRSI FNB58 Scope**: FNB58 supports `0x04` 64-byte HID CRC-8 telemetry and `--experimental` `0x85`/`0x86` trigger writes; FNB58 HID does not expose Source PDO tables (`audit` exits `3`).
- **Linux Permissions**: Install `99-pdprobe.rules` for rootless `MODE="0660", TAG+="uaccess"` access on `5fc9:0063` and `2e3c:5558` (`exit 4` on `EACCES`).
- **Verification Disclosure**: Live Apple Silicon IOKit auditing (`Mac16,6`) and ASan/UBSan unit, protocol-codec, loopback Polar HTTP, `lstat`/`sigaction` rollback, and 124-test E2E suites pass on macOS; Power-Z KM003C and FNIRSI FNB58 wire exchanges are verified against deterministic binary/JSON fixtures, `--sim`, and PTY/sysfs harnesses when physical analyzers are not attached. Always preview triggers with `--dry-run` first.
