# SleepWarden

*A vigilant companion for late-night productivity promises.*

> [!NOTE]
>
> **Platform**: macOS only (Frontend client)
> 
> **Backend**: Cross-platform (Python/FastAPI)

SleepWarden is a playful accountability tool that helps verify if someone truly stays awake during those "I'll work all night" claims. It operates as a **two-tier confirmation system**:

1. **Local verification** — The user must physically interact with a macOS dialog to prove they're awake
2. **Remote verification** — Upon local confirmation, a heartbeat signal is sent to a central server for logging and monitoring

This dual-layer approach ensures that both the user and any interested parties (friends, teammates, or just your future self) can track actual wakefulness patterns.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (macOS Client)                  │
│                                                             │
│  • Random interval prompts                                  │
│  • Native dialog with "I'm alive!" button                   │
│  • Timeout (no click) = no signal                           │
│  • Local logging to ~/Library/Logs/SleepWarden/             │
│  • Configurable via CLI arguments or config file            │
│  • Runs as background process (nohup)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │  POST /i_am_alive (only on confirm)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (FastAPI Server)                 │
│                                                             │
│  • Receives heartbeat signals with timestamps               │
│  • Logs every confirmation with UTC timestamps              │
│  • Request/Response monitoring with detailed logging        │
│  • RESTful API — single endpoint                            │
│  • Runs on port 1216 by default                             │
└─────────────────────────────────────────────────────────────┘
```

### How It Works (Step by Step)

| Step | Component | Action |
|------|-----------|--------|
| 1 | Frontend | Waits random interval (configurated seconds) |
| 2 | Frontend | Displays macOS dialog: *"Confirm your activity"* |
| 3 | User | Clicks **"I'm alive!"** (or dialog times out after configurated seconds) |
| 4 | Frontend | If confirmed → sends `POST /i_am_alive` to Backend |
| 5 | Backend | Logs the confirmation with exact timestamp |
| 6 | Both | Log entries are written locally for audit trail |

**If the user doesn't respond within timeout**, no signal is sent — suggesting sleep may have occurred.

---

## Quick Start

### 1. Backend (Server)

```bash
cd Backend
pip install -r requirements.txt
python main.py
```

The server starts on `http://0.0.0.0:1216`

### 2. Frontend (macOS Client)

```bash
cd Frontend/macOS
chmod +x sleep_warden.sh

# Basic usage (connects to localhost:1216)
./sleep_warden.sh

# Custom server
./sleep_warden.sh -h example.com -p 443 --protocol https

# Using config file
./sleep_warden.sh -c /path/to/config.conf
```

#### Running in Background (Recommended)

```bash
# Start silently in background
nohup ./sleep_warden.sh > /dev/null 2>&1 &

# Find running process
ps aux | grep sleep_warden

# Stop the process
kill <PID>
```

#### Command-line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-h, --host` | API server hostname | `localhost` |
| `-p, --port` | API server port | `1216` |
| `-s, --protocol` | HTTP or HTTPS | `http` |
| `-a, --path` | API endpoint path | `/i_am_alive` |
| `-c, --config` | Path to config file | — |
| `-t, --timeout` | Dialog timeout (seconds) | `60` |
| `--min-interval` | Minimum check interval (sec) | `2700` (45 min) |
| `--max-interval` | Maximum check interval (sec) | `4500` (75 min) |
| `--help` | Show help message | — |

#### Config File Example

Create a file `~/.sleepwarden.conf`:

```ini
API_HOST=my-server.example.com
API_PORT=8443
API_PROTOCOL=https
API_PATH=/api/v1/awake
MIN_INTERVAL=3600
MAX_INTERVAL=7200
TIMEOUT_SECONDS=30
```

Then run:
```bash
./sleep_warden.sh -c ~/.sleepwarden.conf
```

---

## Logging

### Backend Logs
- **Location**: `Backend/SleepWardenBackend.log`
- **Format**: UTC timestamps, request/response details, error traces
- **Level**: DEBUG (includes headers, query params, body)

### Frontend Logs
- **Location**: `~/Library/Logs/SleepWarden/SleepWardenFrontend.log`
- **Contents**: 
  - Each check cycle (notification shown, confirmation status)
  - HTTP response codes from backend
  - Errors and timeouts

### Viewing Logs in Real-Time

```bash
# Backend
tail -f Backend/SleepWardenBackend.log

# Frontend
tail -f ~/Library/Logs/SleepWarden/SleepWardenFrontend.log
```

---

## API Reference

### `POST /i_am_alive`

Records an activity confirmation from the frontend client.

**Request**: No body required.

**Response** `200 OK`:
```json
{
  "timestamp": "2026-07-16T14:30:45.123Z"
}
```

**Error Responses**:
- `500 Internal Server Error` — Unexpected server issue

---

## Use Cases

- **Personal accountability** — Track your own late-night work patterns
- **Team challenge** — See who actually stays awake during hackathons
- **Friend bet** — Settle disputes about who's the true night owl
- **Sleep research** — Gather wakefulness data in a playful way

---

## Disclaimer

**This project was built for playful accountability between consenting individuals.**  
- Always inform participants that monitoring is active.  
- Do not use for surveillance without explicit consent.
