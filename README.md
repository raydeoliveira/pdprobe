# pdprobe (`pdprobe` / `pdctl`)

> **Product Hub:** [raymonddeoliveira.com/software#pdprobe](https://www.raymonddeoliveira.com/software#pdprobe) · **Buy pdprobe Pro ($29):** [Polar Checkout](https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz) · **Verified MCP:** [Glama](https://glama.ai/mcp/servers/raydeoliveira/pdprobe) · **Official MCP Registry:** [io.github.raydeoliveira/pdprobe](https://registry.modelcontextprotocol.io/v0.1/servers?search=raydeoliveira/pdprobe) · **Free Core:** `brew tap raydeoliveira/tap && brew install pdprobe`

Audits USB-C Power Delivery Objects (PDOs), reads live VBUS/IBUS/Power/CC/D+/D-/Temp telemetry, and triggers PD/PPS/EPR-AVS voltages on macOS (Apple Silicon IOKit, `arm64`/`x86_64`) and Linux (`sysfs`, `hidraw`, `usbfs`, `/dev/ttyACM*`) from a **216,992-byte (~212 KB)** C17 binary, `libpdprobe.a` static library (**301,184 bytes / ~294 KB**), and stdio JSON-RPC 2.0 MCP server (`pdctl` symlink alias included).

Measured on macOS `27.3` (`Mac16,6`, `arm64`, `clang`): `pdprobe --version` cold-start latency is **4.65 ms min / 5.40 ms median** with zero external runtime dependencies (`IOKit` + `CoreFoundation` on macOS; `sysfs`, `hidraw`, `usbfs`, and POSIX libc on Linux).

## What It Does / What It Does Not Do

| Target | PDO Audit | Telemetry | Active PD/PPS Trigger | Honest Limits & Notes |
|---|---|---|---|---|
| **Apple Silicon IOKit (`host`, macOS)** | Yes | Yes | No (`exit 3`, read-only) | Live-verified on `Mac16,6`. Masks 64-bit `OSNumber` PDOs `& 0xFFFFFFFF`, scans all 13 slots, redacts `SerialString` unless `--include-serial`. |
| **Linux Host (`host`, `sysfs`)** | Yes | Yes | No (`exit 3`, read-only) | Reads `/sys/class/typec/*/usb_power_delivery`, `ucsi-*` `power_supply`, and `hwmon`. Triggering is unsupported (`exit 3`). |
| **Power-Z KM003C (`0x5fc9:0x0063`)** | Yes | Yes (ADC) | Yes (PD / PPS / EPR-AVS) | USB bulk `PutData` (`0x41`) + CDC-ACM PDM serial trigger (`115200 8N1`). Default safety cap `<= 20000 mV` / `<= 100000 mW` unless `--allow-epr`. |
| **FNIRSI FNB58 (`0x2e3c:0x5558`)** | No (`exit 3`) | Yes (`0x04` 4x15B) | Experimental (`--experimental`) | 64-byte HID + CRC-8 (`poly=0x39, init=0x42`). FNB58 HID does not expose Source PDO tables (`audit` exits `3`). Also maps `0x2e3c:0x0049` and `0x0483:{0x003a,0x003b}`. |
| **Simulator & Fixtures (`--sim` / `--fixture`)** | Yes | Yes | Yes | Exercises real binary/JSON codecs and fault injection across JSON, 64B FNB58 binary, and KM003C `PutData` binary fixtures. |

### Honest Limitations / Hardware Scope

- **Physical Analyzer Verification**: Live Apple Silicon IOKit auditing (`Mac16,6`) and 124 E2E (Tiers 1–5) + ASan/UBSan C unit tests pass on the host. When physical Power-Z KM003C or FNIRSI FNB58 hardware is not attached, KM003C and FNB58 protocol paths are verified against deterministic binary/JSON fixtures, `--sim`, and PTY/sysfs harnesses.
- **No Read-Only Host Triggering**: macOS `IOKit` and Linux `sysfs` do not permit arbitrary sink voltage negotiation from userspace (`pdprobe trigger --device host` returns `HOST_READ_ONLY`, exit `3`).
- **No FNB58 PDO Table**: FNB58 HID reports expose live telemetry (`0x04`) and experimental `0x85`/`0x86` trigger writes, not Source PDO tables (`pdprobe audit --device fnb58` returns `CAPABILITY_UNSUPPORTED`, exit `3`).
- **No Kernel Extensions**: Ships zero kexts, DriverKit extensions, or stealth `LaunchAgents`.

## Install & Uninstall

### Homebrew (macOS arm64 & Linux x86_64)

```bash
brew install raydeoliveira/tap/pdprobe
```

### Build From Source

```bash
# Commercial edition (stripped binary at projects/pdprobe/.build/pdprobe + pdctl symlink)
make -C projects/pdprobe release

# Run ASan + UBSan C unit test suites (commercial and OSS)
make -C projects/pdprobe test
make -C projects/pdprobe test-oss

# Open-Source edition (-DOSS_EDITION, unlocks live trigger offline with no license checks)
make -C projects/pdprobe clean
make -C projects/pdprobe release OSS_EDITION=1
```

There is no `make install` target; copy `.build/pdprobe` (and `ln -sf pdprobe pdctl`) into a directory on your `$PATH` (for example `/usr/local/bin`), or install via Homebrew.

### Linux udev Rules (Rootless USB/HID/CDC-ACM Access)

```bash
sudo cp projects/pdprobe/packaging/udev/99-pdprobe.rules /etc/udev/rules.d/99-pdprobe.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
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

## Quick Start (Human + `--json` Agent + MCP)

### 1. Human Terminal Workflow

```text
$ ./.build/pdprobe --version
pdprobe 0.1.0 (commercial, arm64)

$ ./.build/pdctl --version
pdprobe 0.1.0 (commercial, arm64)

$ ./.build/pdprobe audit --device host
Host: Mac16,6 (macos)
Port port0 (Port-USB-C@1) attached=yes
Device: host (unknown)  VBUS=5245mV IBUS=95mA
  PDO #1 Fixed 5.00V @ 3.00A (15.0W)
  PDO #2 Fixed 9.00V @ 3.00A (27.0W)
  PDO #3 Fixed 12.00V @ 3.00A (36.0W)
  PDO #4 Fixed 15.00V @ 3.00A (45.0W)
  PDO #5 Fixed 20.00V @ 4.80A (96.0W)
  PDO #6 spr_pps 5.00-21.00V @ 5.00A
...
Port port3 (Port-MagSafe 3@1) attached=yes
Device: host (140W USB-C Power Adapter)  VBUS=20000mV IBUS=4690mA
  PDO #1 Fixed 5.00V @ 2.96A (14.8W)
  PDO #2 Fixed 9.00V @ 2.97A (26.7W)
  PDO #3 Fixed 15.00V @ 2.98A (44.7W)
  PDO #4 Fixed 20.00V @ 4.69A (93.8W)
```

### 2. AI-Agent `--json` & Pipe Workflow

Every subcommand supports `--json` returning `{"schema_version": 1, "ok": ..., "command": "...", "data": ..., "error": ...}` on `stdout`:

```text
$ ./.build/pdprobe probe --json
{"schema_version":1,"ok":true,"command":"probe","data":{"devices":[{"device":"host","name":"Mac16,6","vid":"0x0000","pid":"0x0000","transport":"iokit","path":"","serial":null,"serial_redacted":false,"can_audit_pdo":true,"can_telemetry":true,"can_trigger":false,"trigger_status":"unsupported","read_only":true,"max_mv":48000,"max_mw":240000,"honest_limits":"Read-only host port auditing; active PD/PPS triggering is unsupported by macOS IOKit and Linux sysfs (exit 3)."}]},"error":null}

$ ./.build/pdprobe telemetry --device fnb58 --fixture tests/fixtures/fnb58_telemetry_04.bin --count 4 --json
{"schema_version":1,"ok":true,"command":"telemetry","data":{"device":"fnb58","count":4,"samples":[{"timestamp_ns":10000000,"vbus_mv":9000,"ibus_ma":2000,"power_mw":18000,"dp_mv":2700,"dm_mv":2700,"cc1_mv":0,"cc2_mv":0,"temp_c":32.50,"mah_accum":0.0056,"mwh_accum":0.0500},{"timestamp_ns":11000000,"vbus_mv":9001,"ibus_ma":2001,"power_mw":18011,"dp_mv":2700,"dm_mv":2700,"cc1_mv":0,"cc2_mv":0,"temp_c":32.60,"mah_accum":0.0111,"mwh_accum":0.1000},{"timestamp_ns":12000000,"vbus_mv":9002,"ibus_ma":2001,"power_mw":18013,"dp_mv":2700,"dm_mv":2700,"cc1_mv":0,"cc2_mv":0,"temp_c":32.70,"mah_accum":0.0167,"mwh_accum":0.1501},{"timestamp_ns":13000000,"vbus_mv":9003,"ibus_ma":2002,"power_mw":18024,"dp_mv":2700,"dm_mv":2700,"cc1_mv":0,"cc2_mv":0,"temp_c":32.80,"mah_accum":0.0222,"mwh_accum":0.2001}]},"error":null}

$ ./.build/pdprobe trigger --device km003c --fixture tests/fixtures/km003c_spr_pps.json --voltage-mv 9000 --mode pps --dry-run --json
{"schema_version":1,"ok":true,"command":"trigger","data":{"device":"km003c","mode":"pps","pdo_index":6,"rdo_raw":"0x6303843c","dry_run":true,"experimental":false,"allow_epr":false,"applied":false,"verified":false,"reverted":false,"rolled_back":false,"target_voltage_mv":9000,"planned_voltage_mv":9000,"target_current_ma":3000,"readback_vbus_mv":0,"readback_ibus_ma":0,"snapshot_path":null},"error":null}

$ ./.build/pdprobe audit --device km003c --fixture tests/fixtures/km003c_spr_pps.json --json \
  | ./.build/pdprobe trigger --from-json - --device km003c --fixture tests/fixtures/km003c_spr_pps.json --voltage-mv 9000 --dry-run --json
{"schema_version":1,"ok":true,"command":"trigger","data":{"device":"km003c","mode":"auto","pdo_index":2,"rdo_raw":"0x2304b12c","dry_run":true,"experimental":false,"allow_epr":false,"applied":false,"verified":false,"reverted":false,"rolled_back":false,"target_voltage_mv":9000,"planned_voltage_mv":9000,"target_current_ma":3000,"readback_vbus_mv":0,"readback_ibus_ma":0,"snapshot_path":null},"error":null}
```

### 3. Local Stdio MCP Server (`pdprobe mcp`)

`pdprobe mcp` speaks newline-delimited JSON-RPC 2.0 (`protocolVersion: "2024-11-05"`), emits zero stdout bytes for notifications (`notifications/initialized`), and exposes 6 strict `additionalProperties: false` tools (`list_pd_profiles`, `probe_pd_devices`, `audit_pdos`, `read_pd_telemetry`, `trigger_pd_pps`, `reset_pd_safe5v`). Mutating tools default to `dry_run: true`:

```text
$ printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}\n{"jsonrpc":"2.0","method":"notifications/initialized"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list"}\n' | ./.build/pdprobe mcp
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"pdprobe","version":"0.1.0"}}}
{"jsonrpc":"2.0","id":2,"result":{"tools":[...]}}
```

## Safety & Rollback

1. **Probe & Capability Validation**: Active `trigger` reads source PDOs first (when supported) and validates requested voltage/current against negotiated limits.
2. **Default Safety Caps**: Requests above `20000 mV` or `100000 mW` fail closed (`exit 2`) unless `--allow-epr` is passed. FNIRSI FNB58 triggers fail closed unless `--experimental` is passed.
3. **Non-Interactive Guard & Snapshots**: Live writes in non-TTY environments require `--yes` (`exit 2` otherwise). Snapshots (`$XDG_STATE_HOME/pdprobe/snapshot.json`) are written atomically (`O_CREAT | O_EXCL` + `fsync` + `rename`) after `lstat` symlink verification on every path component (`exit 4` on symlink).
4. **Timed Auto-Revert & Signal Cleanup**: Live triggers verify telemetry readback and install non-restarting `sigaction(sa_flags = 0)` + `poll()` handlers (`--confirm-timeout`, default `15s`) to revert to safe 5V on timeout or `SIGINT`/`SIGTERM` (`exit 130`). `pdprobe reset` always reverts to safe 5V in Free Core.
5. **Serial Redaction**: Apple Silicon `AdapterDetails` `SerialString` values are redacted (`serial: null`, `serial_redacted: true`) unless `--include-serial` is explicitly passed.

## Exit Codes & CLI Reference

### Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Runtime / I/O / rollback / telemetry verification failure |
| `2` | Usage / invalid flag / PDO out-of-range / missing `--yes` in non-TTY |
| `3` | Hardware or capability unavailable (no device, host trigger unsupported, FNB58 PDO table unsupported) |
| `4` | Permission / entitlement / `lstat` symlink guard / Linux kernel driver busy |
| `5` | Commercial license missing, invalid, or expired (live `trigger` / `trigger_pd_pps` only; never in `-DOSS_EDITION`, `--dry-run`, `probe`, `audit`, `telemetry`, or `reset`) |
| `130` | Interrupted (`SIGINT` / `SIGTERM`) after clean safe-5V rollback |

### Subcommands & Discovery

- `probe`: Discover host USB-C ports and connected PD testers.
- `audit`: Audit source PDOs and active USB-PD contracts (`--device host|km003c|fnb58|auto`, `--port`, `--include-serial`).
- `telemetry`: Read bounded or `--stream` JSONL telemetry samples (`--count`, `--interval-ms`).
- `trigger`: Negotiate PD/PPS/EPR-AVS voltage/current with snapshot and 5V rollback (`--voltage-mv`, `--current-ma`, `--mode fixed|pps|spr-avs|epr-avs|auto`, `--pdo-index 1..15`, `--confirm-timeout`, `--allow-epr`, `--experimental`, `--dry-run`, `--yes`, `--from-json -`).
- `reset`: Revert active trigger to safe 5V (`--dry-run`, `--yes`). Always Free Core.
- `license`: Manage Polar.sh license (`activate|status|deactivate`, `--key`, `--force-local`, or `PDPROBE_LICENSE_KEY`).
- `mcp`: Run local stdio JSON-RPC 2.0 MCP server.

Run `pdprobe --help` for the full option summary and `pdprobe --describe` for the machine-readable JSON manifest:

```json
{"schema_version":1,"name":"pdprobe","aliases":["pdctl"],"version":"0.1.0","edition":"commercial","arch":"arm64","platform":"macos","global_flags":["--json","--describe","--version","--help","--from-json","--fixture","--sim"],"commands":{"probe":{"side_effect":"read-only","summary":"Discover host USB-C ports and connected PD testers."},"audit":{"side_effect":"read-only","summary":"Audit source PDOs and active USB-PD contracts."},"telemetry":{"side_effect":"read-only","summary":"Read live VBUS/IBUS/Power/D+/D-/CC/Temp samples."},"trigger":{"side_effect":"reversible-write","summary":"Negotiate PD/PPS/EPR-AVS voltage with snapshot and 5V rollback."},"reset":{"side_effect":"reversible-write","summary":"Revert active PD/PPS trigger to safe 5V (Free Core)."},"license":{"side_effect":"reversible-write","summary":"Activate, inspect, or deactivate Polar.sh commercial license."},"mcp":{"side_effect":"read-only","summary":"Run local stdio JSON-RPC 2.0 MCP server (2024-11-05)."}},"exit_codes":{"0":"ok","1":"runtime_error","2":"usage_error","3":"hardware_unavailable","4":"permission_denied","5":"license_required","130":"interrupted_rollback"},"mcp_tools":["list_pd_profiles","probe_pd_devices","audit_pdos","read_pd_telemetry","trigger_pd_pps","reset_pd_safe5v"]}
```

## License & Support

- **License**: Proprietary Commercial EULA (`LICENSE`). Free Core includes `probe`, `audit`, `telemetry`, `reset`, `--dry-run`, `--describe`, `--version`, `--help`, and read-only/dry-run `mcp`. Live hardware `trigger` writes require a **$29 one-time perpetual Polar.sh license** ([Buy pdprobe Pro](https://buy.polar.sh/polar_cl_oS3ab3YwDFdjshc4Fd3dTqa6cGsnJKJyHUnlt2fWdQz), 14-day offline grace cache at `$XDG_CONFIG_HOME/pdprobe/license.json`) or an open-source build compiled with `-DOSS_EDITION`.
- **Security**: See `SECURITY.md` for snapshot/cache permissions, key handling, and vulnerability reporting via GitHub Security Advisories (`raydeoliveira/pdprobe`).
