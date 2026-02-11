# CLAUDE.md - AI Assistant Guide for TalkingPet

## Project Overview

TalkingPet is a Docker-based SIP (Session Initiation Protocol) testing toolkit that wraps the [PJSUA](https://www.pjsip.org/pjsua.htm) command-line SIP client. It enables voice system developers to manually test multi-actor call scenarios (e.g., Alice calls Bob, who adds Carol).

Named after an alien from [Star Control II](https://en.wikipedia.org/wiki/Star_Control_II).

## Tech Stack

- **Base OS:** Alpine Linux 3.23.2
- **SIP client:** pjsua (from Alpine's `pjproject` package)
- **TTS:** espeak
- **Audio conversion:** ffmpeg
- **Scripts:** POSIX sh and bash
- **Container:** Docker + Docker Compose
- **CI/CD:** GitHub Actions
- **Registry:** GitHub Container Registry (ghcr.io)

## Repository Structure

```
talkingpet/
├── register          # Register SIP client, manual control
├── answer            # Register + auto-answer (HTTP 200)
├── play              # Register + auto-answer + play WAV
├── dial              # Outbound call, manual control
├── broadcast         # Outbound call + play WAV
├── reject            # Register + auto-reject (603)
├── busy              # Register + auto-busy (486)
├── help              # Print usage instructions
├── tts               # Text-to-speech WAV generator
├── docker-entrypoint.sh
├── Dockerfile
├── docker-compose.yml
├── build.sh          # Local docker build shortcut
├── generate.sh       # Generate test recordings via TTS
├── recordings/       # WAV files for testing (gitignored)
├── docs/pics/        # Project artwork
├── .env              # Environment config (gitignored)
├── .github/workflows/
│   └── docker-publish.yml  # CI: build + push to GHCR
└── CLAUDE.md         # This file
```

## Build & Run

### Build the Docker image

```bash
docker compose build --force-rm --no-cache --pull talkingpet
```

### Run scripts

```bash
# General pattern
docker compose run --rm --service-ports talkingpet <script> [args...]

# Examples
docker compose run --rm --service-ports talkingpet register alice
docker compose run --rm --service-ports talkingpet answer 0001
docker compose run --rm --service-ports talkingpet play 0001 /recordings/line_1.wav
docker compose run --rm --service-ports talkingpet dial trunk 00491234567890
docker compose run --rm --service-ports talkingpet broadcast trunk 00491234567890 /recordings/trunk.wav
docker compose run --rm --service-ports talkingpet reject 0001
docker compose run --rm --service-ports talkingpet busy 0001

# Override env vars
docker compose run --rm --service-ports -e SIP_PASSWORD=foobar talkingpet play 0001 /recordings/line_1.wav

# Enter container shell for debugging
docker compose run --rm --service-ports --entrypoint=sh talkingpet
```

### Generate test recordings

```bash
./generate.sh
```

## Environment Variables

Configured via `.env` file or `-e` flag with `docker compose run`.

| Variable | Default (compose) | Default (scripts) | Description |
|---|---|---|---|
| `SIP_SERVER_HOST` | `127.0.0.1` | `asterisk` | SIP server address |
| `SIP_SERVER_PORT` | `5060` | `5060` | SIP server port |
| `SIP_SERVER_TRANSPORT` | `udp` | `udp` | Transport protocol (`udp`/`tcp`) |
| `SIP_PASSWORD` | `1234` | `asterisk` | SIP auth password |
| `SIP_USERNAME` | N/A | N/A | Passed as CLI argument per script |

Scripts also accept the legacy `SIP_TRANSPORT` variable for backward compatibility; `SIP_SERVER_TRANSPORT` takes precedence.

## Script Architecture

All SIP scripts follow this pattern:
1. Parse CLI arguments; exit 1 on missing required args
2. Set environment variables with defaults
3. Generate random SIP port (50001-55999) and RTP port (56001-59999) to avoid conflicts
4. Invoke `pjsua` with consistent options + script-specific flags

### Common pjsua options (all scripts)

- `--null-audio` - no audio hardware required
- `--max-calls=4` (or 1 for `dial`)
- `--no-vad` - disable voice activity detection
- `--use-srtp=0 --srtp-secure=0` - SRTP disabled
- `--rtcp-mux` - RTP/RTCP multiplexing
- `--disable-stun` - no STUN
- `--use-compact-form` - compact SIP messages
- `--reg-timeout=90 --rereg-delay=90` - registration timers

### Script-specific behavior

| Script | Auto-answer | Audio | Duration | `--use-cli` |
|---|---|---|---|---|
| `register` | No | Null | Indefinite | No |
| `answer` | 200 | Null | 300s | Yes |
| `play` | 200 | Plays WAV | Indefinite | Yes |
| `dial` | N/A (outbound) | Null | 300s | No |
| `broadcast` | N/A (outbound) | Plays WAV | Indefinite | No |
| `reject` | 603 | Null | Indefinite | Yes |
| `busy` | 486 | Null | Indefinite | Yes |

### pjsua compile-time limits (Alpine package)

- `PJSUA_MAX_CALLS`: 32 (upstream default, not overridden by Alpine)
- Runtime `--max-calls` must not exceed this

## Audio Format Requirements

WAV files for `play` and `broadcast` must be SIP-compatible:
- Sample rate: 8000 Hz
- Channels: 1 (mono)
- Bitrate: 64K

Convert with:
```bash
ffmpeg -y -i SOURCE.wav -ar 8000 -ac 1 -ab 64K CONVERTED.wav
```

Or use the `tts` script inside the container:
```bash
docker compose run --rm talkingpet tts /recordings/myfile "Hello world"
```

## CI/CD

### GitHub Actions workflow (`.github/workflows/docker-publish.yml`)

**Triggers:**
- Push to `master` branch
- Push of semver tags (`v*.*.*`)
- Pull requests to `master` (build only, no push)
- Daily schedule (21:40 UTC)

**What it does:**
1. Builds multi-platform Docker image (`linux/amd64`, `linux/arm64`)
2. Pushes to `ghcr.io/<owner>/talkingpet`
3. Signs image with cosign/Sigstore (non-PR only)

**Required permissions:** `contents: read`, `packages: write`, `id-token: write`

## Key Conventions

- **Shell:** Scripts use `#!/bin/sh` (POSIX) except `broadcast` and `generate.sh` which use `#!/usr/bin/env bash`
- **Indentation:** Tabs in shell scripts
- **Service name:** `talkingpet` (in docker-compose.yml)
- **Recordings dir:** Mounted as `/recordings` inside container
- **Secrets:** `.env` file, gitignored; never commit credentials
- **Git branches:** `master` is the main branch (not `main`)

## Common Issues

- **DNS errors during build:** If building in restricted network environments, ensure the build host can reach `dl-cdn.alpinelinux.org`
- **Port conflicts:** Scripts use random ports to avoid conflicts when running multiple instances concurrently
- **Audio format:** pjsua will fail or produce silence if WAV files aren't in 8000 Hz mono format
- **Max calls exceeded:** If `--max-calls` exceeds the compile-time `PJSUA_MAX_CALLS` (32), pjsua will fail at startup

## Debugging

```bash
# Enter container
docker compose run --rm --service-ports --entrypoint=sh talkingpet

# Install debugging tools
apk add sngrep mc vim

# Capture SIP traffic
sngrep
```
