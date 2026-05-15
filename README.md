# Treasure Hunt game
Treasure Hunt is a poolside shell‑finding game built during my internship. It uses RFID‑tagged shells, an XN‑185 controller, and UDP‑controlled LED lane lines to create an interactive physical game. The Flutter app manages game logic, audio, LED effects, and real‑time tag detection.

---

## Project Structure

```
app_treasuregame/
├── pubspec.yaml                    # Dependencies
├── README.md                       # This file
│
├── assets/
│   └── sounds/                     # ← Place your audio files here
│       ├── correct.mp3             # Played when shell scanned correctly
│       ├── wrong.mp3               # Played when shell scanned at wrong antenna
│       ├── countdown.mp3           # Played during 3-2-1 countdown
│       ├── game_start.mp3          # Played when game begins
│       ├── victory.mp3             # Played on win screen
│       └── splash.mp3              # (optional) water splash effect
│
└── lib/
    ├── main.dart                   # Entry point, app root, screen switcher
    │
    ├── models/
    │   ├── game_config.dart        # ★ All configurable settings (IPs, ports, LEDs)
    │   └── shell_model.dart        # Shell data model (hidden / found / wrong)
    │
    ├── services/
    │   ├── rfid_service.dart       # serial USB connection to XN-185, parses tag messages
    │   ├── led_service.dart        # UDP commands to LED lane line controller
    │   ├── audio_service.dart      # audioplayers wrapper
    │   └── game_controller.dart    # ChangeNotifier: game state machine
    │
    ├── screens/
    │   ├── menu_screen.dart        # Start menu with Help dialog and Start button
    │   ├── countdown_screen.dart   # 3-2-1 animated countdown
    │   ├── game_screen.dart        # 8-shell grid + score + timer
    │   └── victory_screen.dart     # Congrats screen, tap/key to return
    │
    ├── widgets/
    │   └── shell_card.dart         # Animated card: hidden / correct (green) / wrong (red)
    │
    └── config
        └── env.dart
```

---

## Quick-Start Setup

### 1. Install Flutter
https://docs.flutter.dev/get-started/install

### 2. Configure network addresses
## Environment Setup
create `lib/config/env.dart` and fill in your values.
`env.dart` is gitignored and must never be committed.

### 3. Add sound files
Place `.mp3` files in `assets/sounds/`.
Free sources: https://freesound.org  
Suggested searches:
- correct.mp3  → "ding success"
- wrong.mp3    → "buzzer wrong"
- countdown.mp3 → "countdown beep"
- game_start.mp3 → "race start horn"
- victory.mp3  → "fanfare victory"

### 4. Get packages
```bash
flutter pub get
```

### 5. Run
```bash
# On a connected Windows/Linux/Mac or tablet
flutter run

# Build for Windows kiosk
flutter build windows

# Build for Android tablet
flutter build apk
```

---

## Hardware Wiring

```
RFID Tags (on shells)
    ↓
XR-C10 Antenna (poolside) ──→ XR-DR2 Reader
                                    ↓
                            XN-185 (X-talk port)   [serial USB]
                                    ↓
                              This Flutter App    ←→  LED Controller (UDP)
```

### Antenna assignments
| Reader port | Shells | Init command   |
|-------------|--------|----------------|
| X002        | 1 – 4  | X002S[10:3]    |
| X007        | 5 – 8  | X007S[10:3]    |

### Message format (XN-185 → App)
```
X002B[TD=LB1:SHELL1]   → Shell 1 tag detected at Antenna A
X002B[TR=LB1:SHELL1]   → Shell 1 tag removed  at Antenna A
X007B[TD=LB1:SHELL5]   → Shell 5 tag detected at Antenna B
```

---

## LED Commands Reference

| Command                                | Effect                        |
|----------------------------------------|-------------------------------|
| `setBG 000 255 000 000 081`            | All LEDs green                |
| `setBG 255 000 000 000 081`            | All LEDs red                  |
| `setBG 000 100 255 000 081`            | All LEDs blue (idle)          |
| `disco 08 1500`                        | Full disco effect             |
| `discoG 08 0200 0100`                  | Green disco                   |
| `looprace G y` / `looprace G n`        | Green race on/off             |
| `allOff`                               | All LEDs off                  |
| `maxLedPow 100`                        | Full brightness               |

Per-lane LED range for shell N:  
`start = (N-1) * 10`, `end = start + 9`  
Adjust `ledStartForShell()` in `game_config.dart` to match physical layout.

---

## Customising Game Rules

In `game_config.dart`:

```dart
// Set to 0 for unlimited time
static const int gameDurationSeconds = 120;

// Countdown before game starts
static const int countdownSeconds = 3;

// Total shells
static const int totalShells = 8;
```

The "wrong antenna" logic: shell N is **correct** only when scanned at its own reader.  
Shells 1-4 → X002, shells 5-8 → X007.  
Override `shellNumberFromLabel()` to change this mapping.