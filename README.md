# pdprobe (`pdprobe` / `pdctl`)

> **Product Hub:** [raymonddeoliveira.com/software#pdprobe](https://www.raymonddeoliveira.com/software#pdprobe) · **Buy pdprobe Pro ($29):** [Polar Checkout](https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz) · **Verified MCP:** [Glama](https://glama.ai/mcp/servers/raydeoliveira/pdprobe) · **Official MCP Registry:** [io.github.raydeoliveira/pdprobe](https://registry.modelcontextprotocol.io/v0.1/servers?search=raydeoliveira/pdprobe) · **Free Core:** `brew tap raydeoliveira/tap && brew install pdprobe`

Audits USB-C Power Delivery Objects (PDOs) with charger/cable bottleneck diagnostics, reads live VBUS/IBUS/Power/CC/D+/D-/Temp telemetry with session summaries, and triggers PD/PPS/EPR-AVS voltages on macOS (Apple Silicon IOKit, `arm64`/`x86_64`) and Linux (`sysfs`, `hidraw`, `usbfs`, `/dev/ttyACM*`) from a **217,264-byte (~212 KB)** C17 binary, `libpdprobe.a` static library (**307,472 bytes / ~300 KB**), and stdio JSON-RPC 2.0 MCP server (`pdctl` symlink alias included).

Measured on macOS `27.3` (`Mac16,6`, `arm64`, `clang`): `pdprobe --version` cold-start latency is **4.65 ms min / 5.40 ms median** with zero external runtime dependencies (`IOKit` + `CoreFoundation` on macOS; `sysfs`, `hidraw`, `usbfs`, and POSIX libc on Linux).

## 5-Second Start (No Dongle Required)

Plug any USB-C charger or hub into your Mac or Linux laptop and diagnose why you're getting 65W or 93W instead of 140W:

```bash
brew tap raydeoliveira/tap && brew install pdprobe
pdprobe audit
```

```text
Host: Mac16,6 (macos)
Port port0 (Port-USB-C@1) attached=yes
Device: host (unknown)  VBUS=5245mV IBUS=102mA
  PDO #1 Fixed 5.00V @ 3.00A (15.0W)
  PDO #2 Fixed 9.00V @ 3.00A (27.0W)
  PDO #3 Fixed 12.00V @ 3.00A (36.0W)
  PDO #4 Fixed 15.00V @ 3.00A (45.0W)
  PDO #5 Fixed 20.00V @ 4.80A (96.0W)
  PDO #6 spr_pps 5.00-21.00V @ 5.00A
  Summary: Draw/contract 0W is below 105W source max (104W headroom) (PPS, EPR, 5A cable)
Port port1 (Port-USB-C@2) attached=no
Device: host (unknown)  VBUS=0mV IBUS=0mA
  Summary: Unattached (no active USB-C PD contract)
Port port2 (Port-USB-C@3) attached=yes
Device: host (unknown)  VBUS=5210mV IBUS=5mA
  PDO #1 Fixed 5.00V @ 3.00A (15.0W)
  PDO #2 Fixed 9.00V @ 3.00A (27.0W)
  PDO #3 Fixed 12.00V @ 3.00A (36.0W)
  PDO #4 Fixed 15.00V @ 3.00A (45.0W)
  PDO #5 Fixed 20.00V @ 3.25A (65.0W)
  PDO #6 spr_pps 3.30-16.00V @ 3.25A
  Summary: Near source max (65W / 65W max; 0W headroom) (PPS, 5A cable)
Port port3 (Port-MagSafe 3@1) attached=yes
Device: host (140W USB-C Power Adapter)  VBUS=20000mV IBUS=4690mA
  PDO #1 Fixed 5.00V @ 2.96A (14.8W)
  PDO #2 Fixed 9.00V @ 2.97A (26.7W)
  PDO #3 Fixed 15.00V @ 2.98A (44.7W)
  PDO #4 Fixed 20.00V @ 4.69A (93.8W)
  Summary: Near source max (93W / 93W max; 0W headroom) (EPR, 5A cable)
```

## What It Does / What It Does Not Do

| Target | PDO Audit | Telemetry | Active PD/PPS Trigger | Honest Limits & Notes |
|---|---|---|---|---|
| **Apple Silicon IOKit (`host`, macOS)** | Yes | Yes | No (`exit 3`, read-only) | Live-verified on `Mac16,6`. Masks 64-bit `OSNumber` PDOs `& 0xFFFFFFFF`, scans all 13 slots, redacts `SerialString` unless `--include-serial`. |
| **Linux Host (`host`, `sysfs`)** | Yes | Yes | No (`exit 3`, read-only) | Reads `/sys/class/typec/*/usb_power_delivery`, `ucsi-*` `power_supply`, and `hwmon`. Triggering is unsupported (`exit 3`). |
| **Power-Z KM003C (`0x5fc9:0x0063`)** | Yes | Yes (ADC) | Yes (PD / PPS / EPR-AVS) | USB bulk `PutData` (`0x41`) + CDC-ACM PDM serial trigger (`115200 8N1`). Default safety cap `<= 20000 mV` / `<= 100000 mW` unless `--allow-epr`. |
| **FNIRSI FNB58 (`0x2e3c:0x5558`)** | No (`exit 3`) | Yes (`0x04` 4x15B) | Experimental (`--experimental`) | 64-byte HID + CRC-8 (`poly=0x39, init=0x42`). FNB58 HID does not expose Source PDO tables (`audit` exits `3`). Also maps `0x2e3c:0x0049` and `0x0483:{0x003a,0x003b}`. |
| **Simulator & Fixtures (`--sim` / `--fixture`)** | Yes | Yes | Yes | Exercises real binary/JSON codecs and fault injection across JSON, 64B FNB58 binary, and KM003C `PutData` binary fixtures. |

### Honest Limitations & Hardware Testing Callout

- **Physical Analyzer Verification**: Live Apple Silicon IOKit auditing (`Mac16,6`) and 124 E2E (Tiers 1–5) + ASan/UBSan C unit tests pass on the host. Physical Power-Z KM003C and FNIRSI FNB58 hardware were not attached during automated CI; their binary packet codecs, CRC-8, telemetry streaming, and 5V rollback are verified against deterministic fixtures, `--sim`, and PTY/sysfs harnesses.
- **Hardware Compatibility Reports**: Have a KM003C, FNB58, or multi-port GaN charger? Paste `pdprobe probe --json` and `pdprobe audit` outputs in [GitHub Discussions](https://github.com/raydeoliveira/pdprobe/discussions) so we can expand the verified hardware table.
- **No Read-Only Host Triggering**: macOS `IOKit` and Linux `sysfs` do not permit arbitrary sink voltage negotiation from userspace (`pdprobe trigger --device host` returns `HOST_READ_ONLY`, exit `3`).
- **No FNB58 PDO Table**: FNB58 HID reports expose live telemetry (`0x04`) and experimental `0x85`/`0x86` trigger writes, not Source PDO tables (`pdprobe audit --device fnb58` returns `CAPABILITY_UNSUPPORTED`, exit `3`).
- **No Kernel Extensions**: Ships zero kexts, DriverKit extensions, or stealth `LaunchAgents`.

## Free Core vs. Pro ($29 One-Time)

| Feature | Free Core | Pro ($29 one-time) |
|---|---|---|
| `probe`, `audit` (with bottleneck `diagnostics`), `telemetry` (`--stream` + `summary`) | Included | Included |
| `reset` (emergency revert to safe 5V), `--dry-run`, `--describe`, `--json` | Included | Included |
| Interactive fixed SPR live triggers (`5V–20V`, `<= 100W`, TTY confirm + 5V rollback) | Included | Included |
| `pdprobe mcp` read-only tools & `trigger_pd_pps` with `dry_run: true` | Included | Included |
| Programmable **PPS (`20 mV` stepping)** & **EPR-AVS (`>20V`, up to `48V / 240W`)** triggers | — | Included |
| Unattended / scripted trigger automation (`--yes`, `--from-json -`) | — | Included |
| Live AI-agent MCP hardware writes (`trigger_pd_pps` with `dry_run: false`) | — | Included |

Commercial Pro licenses are one-time perpetual via [Polar.sh](https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz) (3 personal machines, 14-day offline grace cache at `$XDG_CONFIG_HOME/pdprobe/license.json`).

## Install & Uninstall

### Homebrew (macOS arm64 & Linux x86_64)

```bash
brew tap raydeoliveira/tap
brew install pdprobe
```

### Linux x86_64 Direct Tarball + Rootless udev Rules

```bash
curl -fLO https://github.com/raydeoliveira/pdprobe/releases/download/v0.2.0/pdprobe-0.2.0-linux-x86_64.tar.gz
curl -fLO https://github.com/raydeoliveira/pdprobe/releases/download/v0.2.0/SHA256SUMS.txt
sha256sum --ignore-missing -c SHA256SUMS.txt
tar -xzf pdprobe-0.2.0-linux-x86_64.tar.gz
sudo install -m 0755 pdprobe-0.2.0-linux-x86_64/pdprobe /usr/local/bin/pdprobe
sudo ln -sf pdprobe /usr/local/bin/pdctl
sudo install -m 0644 pdprobe-0.2.0-linux-x86_64/99-pdprobe.rules /etc/udev/rules.d/99-pdprobe.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### One-Click MCP Bundle & Client Config (Claude / Cursor / Codex)

Download `pdprobe-0.2.0-macos-arm64.mcpb` from [GitHub Releases](https://github.com/raydeoliveira/pdprobe/releases/tag/v0.2.0), or point any MCP client at `pdprobe` installed on your `$PATH`:

```json
{
  "mcpServers": {
    "pdprobe": {
      "command": "pdprobe",
      "args": ["mcp"],
      "env": {
        "PDPROBE_LICENSE_KEY": ""
      }
    }
  }
}
```

### Build From Source (`pdprobe-src`)

```bash
make release                # Commercial binary (stripped pdprobe + pdctl symlink)
make test && make test-oss  # ASan + UBSan unit suites
make clean && make release OSS_EDITION=1  # -DOSS_EDITION (unlocks live triggers offline)
```

### Clean Uninstall

```bash
# If installed via Homebrew:
brew uninstall pdprobe

# If installed manually, plus state/config cleanup:
rm -f /usr/local/bin/pdprobe /usr/local/bin/pdctl
sudo rm -f /etc/udev/rules.d/99-pdprobe.rules
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/pdprobe" "${XDG_STATE_HOME:-$HOME/.local/state}/pdprobe"
```

## AI-Agent `--json`, UNIX Pipes & Stdio MCP

With PDProbe installed, add the [agent instructions](SKILL.md) to your project for inspecting USB-C power profiles and interpreting charger telemetry.

```sh
npx skills add raydeoliveira/pdprobe
```

### 1. Structured `--json` & Pipe Composability

Every subcommand emits `{"schema_version": 1, "ok": ..., "command": "...", "data": ..., "error": ...}` on `stdout`:

```bash
pdprobe probe --json
pdprobe audit --device host --json
pdprobe telemetry --device km003c --sim --count 4 --json
pdprobe trigger --device km003c --sim --voltage-mv 9000 --mode pps --dry-run --json

# Pipe upstream audit JSON directly into trigger preview:
pdprobe audit --device km003c --sim --json \
  | pdprobe trigger --from-json - --device km003c --sim --voltage-mv 9000 --dry-run --json
```

### 2. Interactive Free SPR Trigger vs. Pro Trigger

```bash
# Free Core: interactive fixed SPR trigger (5V-20V, <=100W) with 5V auto-revert
pdprobe trigger --device km003c --voltage-mv 9000 --mode fixed

# Commercial Pro: activate once, then run programmable PPS / EPR-AVS / --yes scripts
pdprobe license activate --key "PDPROBE-XXXX-XXXX-XXXX"
pdprobe trigger --device km003c --voltage-mv 11400 --current-ma 3000 --mode pps --yes --json
```

### 3. Local Stdio MCP Server (`pdprobe mcp`)

`pdprobe mcp` speaks newline-delimited JSON-RPC 2.0 (`protocolVersion: "2024-11-05"`), emits zero stdout bytes for notifications (`notifications/initialized`), and exposes 6 strict `additionalProperties: false` tools (`list_pd_profiles`, `probe_pd_devices`, `audit_pdos`, `read_pd_telemetry`, `trigger_pd_pps`, `reset_pd_safe5v`). Mutating tools default to `dry_run: true`:

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}\n{"jsonrpc":"2.0","method":"notifications/initialized"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list"}\n' | pdprobe mcp
```

## Safety & Rollback

1. **Probe & Capability Validation**: Active `trigger` reads source PDOs first (when supported) and validates requested voltage/current against negotiated limits.
2. **Default Safety Caps**: Requests above `20000 mV` or `100000 mW` fail closed (`exit 2`) unless `--allow-epr` is passed. FNIRSI FNB58 triggers fail closed unless `--experimental` is passed.
3. **Non-Interactive Guard & Snapshots**: Live writes in non-TTY environments require `--yes` (`exit 2` otherwise). Snapshots (`$XDG_STATE_HOME/pdprobe/snapshot.json`) are written atomically (`O_CREAT | O_EXCL` + `fsync` + `rename`) after `lstat` symlink verification on every path component (`exit 4` on symlink).
4. **Timed Auto-Revert & Signal Cleanup**: Live triggers verify telemetry readback and install non-restarting `sigaction(sa_flags = 0)` + `poll()` handlers (`--confirm-timeout`, default `15s`) to revert to safe 5V on timeout or `SIGINT`/`SIGTERM` (`exit 130`). `pdprobe reset` always reverts to safe 5V in Free Core.
5. **Serial Redaction**: Apple Silicon `AdapterDetails` `SerialString` values are redacted (`serial: null`, `serial_redacted: true`) unless `--include-serial` is passed.

## Exit Codes & CLI Reference

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Runtime / I/O / rollback / telemetry verification failure |
| `2` | Usage / invalid flag / PDO out-of-range / missing `--yes` in non-TTY |
| `3` | Hardware or capability unavailable (no device, host trigger unsupported, FNB58 PDO table unsupported) |
| `4` | Permission / entitlement / `lstat` symlink guard / Linux kernel driver busy |
| `5` | Commercial Pro license missing, invalid, or expired (PPS/EPR, scripted `--yes`/`--from-json`, or live `trigger_pd_pps` with `dry_run: false`) |
| `130` | Interrupted (`SIGINT` / `SIGTERM`) after clean safe-5V rollback |

Run `pdprobe --help` for the full option summary and `pdprobe --describe` for the machine-readable JSON manifest (`version: "0.2.0"`).

## License & Support

- **License**: Proprietary Commercial EULA (`LICENSE`). Open-source `-DOSS_EDITION` compile seam included in source.
- **Security**: See `SECURITY.md` for snapshot/cache permissions, key handling, and vulnerability reporting via GitHub Security Advisories (`raydeoliveira/pdprobe`).
