# SleepWarden

*A vigilant companion for late-night productivity promises.*

SleepWarden is a lighthearted productivity monitor that helps verify if someone truly stays awake during those "I'll work all night" claims. It periodically prompts the user to confirm their consciousness and reports back to a central server.

## Architecture

```
┌─────────────────────────────────────────┐
│               Frontend                  │
│           (macOS Client)                │
│                                         │
│  • Random interval prompts (45-75 min)  │
│  • Native macOS dialog notifications    │
│  • Automatic activity confirmation      │
│  • Local logging                        │
└─────────────┬───────────────────────────┘
              │  POST /i_am_alive
              ▼
┌─────────────────────────────────────────┐
│               Backend                   │
│          (FastAPI Server)               │
│                                         │
│  • Receives heartbeat signals           │
│  • Logs all activity with timestamps    │
│  • Request/Response monitoring          │
└─────────────────────────────────────────┘
```

## Quick Start

### Backend

```bash
cd Backend
pip install -r requirements.txt
python main.py
```

The server starts on `http://0.0.0.0:1216`

### Frontend (macOS)

```bash
chmod +x Frontend/MacOS/sleep_warden.sh
./Frontend/MacOS/sleep_warden.sh
```

For background execution:

```bash
nohup ./Frontend/MacOS/sleep_warden.sh > /dev/null 2>&1 &
```

## How It Works

1. **Frontend** runs as a background process on the target's machine
2. At random intervals (45-75 minutes), it displays a macOS dialog: *"Confirm your activity"*
3. If the user clicks **"I'm alive!"**, a heartbeat is sent to the backend
4. If the dialog times out (5 minutes), no signal is sent — suggesting sleep may have occurred
5. **Backend** records each confirmed heartbeat with precise UTC timestamps

## Logging

- **Backend**: `Backend/SleepWardenBackend.log`
- **Frontend**: `~/Library/Logs/SleepWarden/SleepWardenFrontend.log`

## API Reference

### `POST /i_am_alive`

Records an activity confirmation.

**Response** `200 OK`

```json
{
  "timestamp": "2026-07-16T14:30:45.123Z"
}
```

## Disclaimer

This project was built for playful accountability between friends. Use responsibly and with consent. 😴
