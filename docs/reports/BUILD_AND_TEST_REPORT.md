# Build and Test Report: Battery Test System Simulation (LabVIEW 2019)

**Date:** 2026-11-23 · **LabVIEW:** 2019 (19.0f2, 32-bit) · **Mode:** SIMULATION ONLY. **No physical battery, shunt, thermocouple, power supply, load or cRIO I/O was used or tested.**

## 1. Deliverables (`Build/Simulation/`)

| File | What it is | Built by |
|---|---|---|
| `Battery_Test_System_Simulation.lvproj` | Working copy of the project; the simulation lives under My Computer | copy of the original |
| `Battery_Test_System_Main.vi` | Main application: event loop, state machine, simulation, safety, log, graphs, CSV | generated (AIXML → LabVIEW 2019 file) |
| `Sim_Validate_Setpoints.vi`, `Sim_Update_Model.vi`, `Sim_Check_Safety.vi`, `Sim_Check_Completion.vi`, `Sim_Save_CSV.vi` | SubVIs; `Sim_Update_Model.vi` is the hardware-abstraction point | generated |
| `Sim_State_Enum.ctl` | INIT, IDLE, CHARGING, DISCHARGING, STOPPED, FAULT | user |
| `Sim_Data.ctl`, `Sim_Settings.ctl`, `Sim_Log_Record.ctl` | Typedefs (nested links verified) | created by LabVIEW 2019 via helper |
| `Test_State_Enum2.ctl` | Charge/Discharge mode (reused) | original |

The original project in the repository root is unchanged. A byte copy with hashes is in `Build/Original_Backup_2026-11-23/`.

## 2. How the LabVIEW 2019 files were produced

The MCP server writes LabVIEW 2020+ files by default, which LabVIEW 2019 refused (Error 1125). The MCP composer was therefore called directly with `--lv-version 19`. Every generated file was then opened, run and, where relevant, re-saved **by LabVIEW 2019 itself**. Details are in `BUILD_MANIFEST.md`.

## 3. Unit tests: subVIs (LabVIEW 2019, automated over ActiveX)

`Build/Tools_LV2019/tests/test_Sim_Validate_Setpoints.vbs`: **9/9 PASS**
`Build/Tools_LV2019/tests/test_subvis.vbs` on the installed files: **32/32 PASS**

| SubVI | Cases |
|---|---|
| Sim_Validate_Setpoints | valid; at limits; I = 0; I < 0; V > max; C-rate > max; duration > max; all zero; tiny positive |
| Sim_Update_Model | charge step (SOC, V, I, T, time); discharge step (I negative); idle (outputs OFF, I = 0, elapsed frozen); SOC clamp at 100; interlock in every state |
| Sim_Check_Safety | normal; OV; OC (abs); OT; interlock; E-Stop priority + first fault time kept; injection; latched fault keeps the command status text |
| Sim_Check_Completion | not done; charge half-cycle; full cycle → Cycle Count = 1; duration expiry not counted |
| Sim_Save_CSV | header + rows ending CRLF; enum names in CSV; unwritable path → "Save FAILED (error 8)" |

## 4. Acceptance tests: main VI (LabVIEW 2019, operator clicks, indicators logged every 250 ms)

Logs are in `Build/Tools_LV2019/tests/out/`: `acceptance_log_run2_steps1-10.txt` (run 2) and `acceptance_log.txt` (run 3).

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | Run → INIT → IDLE, outputs OFF | **PASS** | "Initialized. SIMULATION MODE …", SOC 50, V 12, T 25, PS/Load OFF |
| 2 | Invalid input (Charge Current = 0) | **PASS** | "Rejected: Current setpoint must be > 0 …", no state change |
| 3 | Charge start + progression + completion | **PASS** | PS ON / Load OFF; SOC 50 → 100 in 30.0 s (speed ×60); "Charge complete"; outputs OFF |
| 4 | Discharge start + progression + completion, cycle count | **PASS** | Load ON / PS OFF, I negative; SOC 100 → 0 in 60.2 s; "Full charge+discharge cycle completed. Cycle Count incremented." |
| 5 | Manual Stop | **PASS** | "Stopped by operator - outputs OFF (half-cycle not counted)" |
| 6 | Mode change while running | **PASS** | "Mode change ignored while running - press Stop first."; charging continued until Stop |
| 7 | Fault injection (overvoltage) | **PASS** | FAULT, Fault LED ON, outputs OFF, reason and values shown |
| 8 | Start while faulted | **PASS** (after fix) | "Start blocked: fault latched …" stays visible |
| 9 | Reset with the cause still present | **PASS** | Stays in FAULT |
| 10 | Reset after removing the cause | **PASS** | "Fault reset requested - returning to IDLE." |
| 11 | Save CSV (dialog) | **PASS** (after fix) | "Saved successfully: …\acceptance.csv"; 1045 rows + header |
| 12 | Save to an unwritable path | **PASS** | "Save FAILED (error 8) …"; VI kept running |
| 13 | Save to an existing file → No | **PASS** | "Save cancelled."; file not overwritten |
| 14 | Close | **PASS** | "Closing - outputs OFF.", VI stopped by itself |
| 15 | Repeat start/stop | **PASS** | 6 starts and stops across runs 2–3; no stuck latched buttons |

**CSV analysis** (`acceptance.csv`, 1045 samples):
- States logged: IDLE 582, CHARGING 103, STOPPED 198, FAULT 162.
- Rows with supply **and** load ON: **0**. Supply ON outside CHARGING: **0**. Any output ON in FAULT: **0**.
- Measured time step: 0.200 s average, 0.203 s maximum. dt comes from Tick Count and is clamped to `Max dt`.

## 5. Defects found and fixed during testing

| Defect | Fix | Re-test |
|---|---|---|
| Save showed no dialog: an empty path control gave error 1430 | `Sim_Save_CSV.vi`: an empty path calls Open/Create/Replace with the path **unwired** | Step 11 PASS; unit tests 32/32 |
| "Start blocked" message was overwritten every iteration while a fault was latched | `Sim_Check_Safety.vi` keeps the Status Message when the fault is already latched | New unit test + step 8 PASS |

The old versions are kept in `Build/Tools_LV2019/staging/replaced_20261123/`.

## 6. Not tested / known limitations

- **No hardware.** All values are simulated demonstration values. The limits in `Simulation Settings (DEMO ONLY)` are **not** Li-ion safety limits, and the model is an idealized C-rate/first-order model, not an electrochemical one.
- Overcurrent, overtemperature and E-Stop injection were tested at unit level only. Overvoltage was tested end to end.
- Panel look: the controls are auto-arranged in the default style. Silver styling is optional and manual; see `docs/build/UI_STYLING_GUIDE.md`.
- Cosmetic: the subVI connector panes use pattern 4833 with some inputs on the right edge, and the main diagram is wider than one screen (Clean Up Diagram, Ctrl+U).
- `Save` writes the last `History Length` samples (default 3000 ≈ 10 min at 200 ms).

## 7. Future hardware phase (out of scope)

Replace `Sim_Update_Model.vi` with a cRIO I/O VI that has the same connector pane:
- read V, I and T (NI 9205/9219)
- drive the supply reference and enables (NI 9263/9401) **only** from the interlocked `Sim PS Enable` / `Sim Load Enable` flags

Keep `Sim_Check_Safety.vi`, but back it with a real BMS or hardware interlock.
