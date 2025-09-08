# Ultrasonic Melody Trainer (PIC18F4321)

![GitHub repo size](https://img.shields.io/github/repo-size/AlbertoMarquillas/ultrasonic-melody-trainer-pic18f4321)
![GitHub license](https://img.shields.io/github/license/AlbertoMarquillas/ultrasonic-melody-trainer-pic18f4321)
![GitHub last commit](https://img.shields.io/github/last-commit/AlbertoMarquillas/ultrasonic-melody-trainer-pic18f4321)
![GitHub issues](https://img.shields.io/github/issues/AlbertoMarquillas/ultrasonic-melody-trainer-pic18f4321)

---

## 📖 Overview

This project implements a **"theremin-style" melody trainer** on the **PIC18F4321** microcontroller, written entirely in **Assembly**. 

The firmware ingests notes and durations from an external bus, stores them in memory, and manages:
- **7-segment display** and **LED indicators** for current note and duration.
- **Speaker (PWM)** to generate tones.
- **HC-SR04 ultrasonic sensor** to capture the player's hand distance and match it to the expected note.
- **Servo motor** for real-time scoring feedback.
- **Handshake signals** (`NewNote`, `StartGame`, `ACK`) with the external interface.

This repository corresponds to **Phase 2** of the original academic practice, refactored and documented as a professional, portfolio-ready firmware project.

---

## 📂 Repository Structure

```
├─ src/firmware/         # Assembly source code (fase2.asm)
├─ test/                 # Validation and smoke tests
├─ docs/
│  ├─ assets/            # Board photos, diagrams
│  └─ specs/             # Original brief + memory report
├─ tools/                # Flashing and smoke-test scripts (PowerShell)
├─ build/                # Build outputs (ignored)
└─ README.md             # Project documentation
```

---

## ⚙️ Getting Started

### Requirements
- **MPLAB X IDE** (v6.x recommended)
- **XC8 toolchain** (v2.x)
- **PICkit 3/4** or compatible programmer
- Hardware: PIC18F4321 + HC-SR04 + 7-segment + LEDs + servo + speaker

### Build & Flash (Windows PowerShell)
```powershell
# Open MPLAB X project or assemble manually
git clone https://github.com/AlbertoMarquillas/ultrasonic-melody-trainer-pic18f4321.git
cd ultrasonic-melody-trainer-pic18f4321
# (Open src/firmware/fase2.asm in MPLAB X and build/flash)
```

---

## 🎮 Usage
1. Connect the board with peripherals (HC-SR04, servo, LEDs, speaker).
2. Load the firmware onto the PIC18F4321.
3. Start the game with `StartGame` signal.
4. The firmware:
   - Displays current note/duration.
   - Waits for player to reproduce note via HC-SR04.
   - Validates input and updates score via servo.

---

## 📊 Features
- Full Assembly implementation
- Real-time distance-to-note mapping
- PWM-based audio tone generation
- Visual + mechanical feedback (7-seg, LEDs, servo)
- Handshake protocol with external bus

---

## 🧪 Tests & Validation
- **Smoke test**: firmware boots, toggles LEDs, responds to `StartGame`.
- **Functional test**: ultrasonic sensor correctly mapped to notes.
- **Theoretical overlay**: matches expected musical notes/durations with measured PWM signals.

---

## 📝 What I Learned
- Low-level control of PIC18F4321 peripherals (timers, PWM, I/O).
- Implementing UART-like handshakes via discrete signals.
- Mapping physical distance (HC-SR04) to musical pitch.
- Structuring academic firmware into a portfolio-ready repository.

---

## 🚀 Roadmap
- [ ] Add PowerShell scripts for automated flashing & UART smoke test.
- [ ] Include block diagram and pinout in `docs/assets/`.
- [ ] Provide HEX build as release asset (`v0.1.0`).
- [ ] Extend test coverage with waveform validation.

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).
