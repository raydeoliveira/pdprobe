# Security Policy — Pdprobe

Report security vulnerabilities privately via GitHub Security Advisories for `raydeoliveira/pdprobe`.

## Scope & Security Controls
- **Symlink & Snapshot Guard**: Snapshot (`$XDG_STATE_HOME/pdprobe/snapshot.json`) and license cache (`$XDG_CONFIG_HOME/pdprobe/license.json`) directories are verified component-by-component with `lstat()` (failing closed with `exit 4` on symlinks) and written atomically via `O_CREAT | O_EXCL | O_NOFOLLOW` + `fsync()` + `rename()` with `0600` file permissions (`0700` directory mode).
- **License Key Handling**: `pdprobe license` invokes `curl` directly via `posix_spawnp` (zero shell execution) passing the license payload over stdin via `--data-binary @-` so license keys never appear in process `argv`. Cached keys are stored masked in status output.
- **API Endpoint Validation**: `PDPROBE_POLAR_API_URL` (default `https://api.polar.sh`) accepts only `https://` URLs or explicit loopback `http://` (`127.0.0.1`, `localhost`, `[::1]`) for local test harnesses.
- **Adapter Serial Redaction**: Apple Silicon `AdapterDetails` `SerialString` values are redacted by default (`serial: null`, `serial_redacted: true`) unless `--include-serial` is explicitly passed.
- **Hardware Write & Rollback Safety**: Live hardware triggers require `--yes` in non-TTY sessions (`exit 2`), enforce `<= 20V / <= 100W` caps unless `--allow-epr` is passed, require `--experimental` for FNIRSI FNB58 `0x85`/`0x86` writes, and install non-restarting `sigaction(sa_flags = 0)` + `poll()` handlers to revert to safe 5V on timeout or `SIGINT`/`SIGTERM` (`exit 130`).
