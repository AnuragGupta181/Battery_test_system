# Battery Test System: LabVIEW 2019 Simulation

A battery charge/discharge test application for an **NI cRIO-9063** with NI 9205 / 9219 / 9263 / 9401 modules, built and tested in **LabVIEW 2019**.

The current phase is **SIMULATION ONLY**: every value is simulated, and no battery or hardware I/O is used.

## Status
| | |
|---|---|
| Main VI | `Build/Simulation/Battery_Test_System_Main.vi` runs in LabVIEW 2019 |
| Tests | Unit 41/41 and acceptance 15/15 **passed** (see `docs/reports/BUILD_AND_TEST_REPORT.md`) |
| UI | Functional, auto-arranged panel. Optional Silver styling: `docs/build/UI_STYLING_GUIDE.md` |
| Hardware | Not connected yet. Low-cost 4S 18650 plan (≈ ₹2,000 besides the cRIO): `docs/hardware/CRIO_HARDWARE_INTEGRATION.md` |

## Quick start
1. Open **`Build/Simulation/Battery_Test_System_Simulation.lvproj`** in **LabVIEW 2019** (32-bit).
2. Open **My Computer ▸ Main ▸ `Battery_Test_System_Main.vi`** and click **Run**.
3. Pick **Operation Mode** (Charge / Discharge), check **Charge Settings** or **Discharge Settings**, then press **Start**.
   - For a fast demo, set `Simulation Settings (DEMO ONLY) ▸ SOC Speed Factor = 60`.
4. **Stop** stops the operation; **Save** writes a CSV (file dialog); **Close** shuts down safely.
5. Use the `Inject …` switches in Simulation Settings to test faults, then press **Reset Fault**.

## What it does
- **One event-driven loop.** The event structure handles Start, Stop, Operation Mode, Save, Reset Fault, Close and the panel's close box. The state machine has INIT, IDLE, CHARGING, DISCHARGING, STOPPED and FAULT.
- **Simulation model** (`Sim_Update_Model.vi`):
  - SOC follows the ideal C-rate formula `dSOC = C × 100 × dt / 3600`.
  - Voltage and current approach their setpoints with a first-order response.
  - Temperature rises with I² and cools toward ambient.
  - The time step `dt` is measured, not assumed.
- **Output interlock:** the supply is enabled only in CHARGING and the load only in DISCHARGING. Both are OFF in every other state, and they are never ON together (verified in the CSV log).
- **Safety (simulated):**
  - Priority order: E-Stop, overvoltage, overcurrent, overtemperature, interlock.
  - A fault latches until Reset, and Reset works only once the cause is gone.
- **Cycle count:** +1 only when a full charge **and** discharge reach their SOC targets. A Stop, a fault or a duration expiry doesn't count.
- **CSV log:** header plus one row per sample (last 3000 samples). The save dialog asks before overwriting an existing file.

> All limits in `Simulation Settings (DEMO ONLY)` are demonstration values, **not** lithium-ion safety limits.

## Folder layout
```
/                                  ORIGINAL project (unchanged): BATTERY TEST SYSTEM FINAL.lvproj, user_interface.vi, ...
Build/
  Simulation/                      WORKING simulation project (open this)
    Battery_Test_System_Simulation.lvproj
    Battery_Test_System_Main.vi    main application
    Sim_*.vi                       subVIs (validate, model, safety, completion, CSV)
    Sim_*.ctl, Test_State_Enum2.ctl  typedefs
  Original_Backup_2026-11-23/      byte copy of the original files
  Tools_LV2019/                    generator sources (AIXML), LabVIEW 2019 helper VIs, test scripts
  Compat_Probe/                    LabVIEW 2019 compatibility probe (evidence)
docs/
  requirements/PROJECT_PROMPT.md   requirements and acceptance criteria
  build/BUILD_GUIDE.md             how every part is built
  build/UI_STYLING_GUIDE.md        optional Silver UI, done by hand
  hardware/CRIO_HARDWARE_INTEGRATION.md   hardware list, module/pin wiring, bring-up
  reports/BUILD_MANIFEST.md        build log, decisions, file hashes
  reports/BUILD_AND_TEST_REPORT.md test results
  reference/                       background paper
CLAUDE.md                          notes for the AI coding agent
```

## Re-running the tests
These run in 32-bit VBScript, which drives LabVIEW 2019 over ActiveX, so LabVIEW 2019 must be open:
```
C:\Windows\SysWOW64\cscript.exe //nologo Build\Tools_LV2019\tests\test_Sim_Validate_Setpoints.vbs Build\Simulation\Sim_Validate_Setpoints.vi
C:\Windows\SysWOW64\cscript.exe //nologo Build\Tools_LV2019\tests\test_subvis.vbs Build\Simulation Build\Tools_LV2019\tests\out
C:\Windows\SysWOW64\cscript.exe //nologo Build\Tools_LV2019\tests\monitor_main.vbs Build\Simulation\Battery_Test_System_Main.vi Build\Tools_LV2019\tests\out\log.txt 30
```
Use absolute paths if a relative one isn't found. The third command opens the main VI and logs every indicator change while you click through the acceptance steps.

## Requirements
- Windows, **LabVIEW 2019 32-bit** (no newer version needed or used).
- For the hardware phase: LabVIEW 2019 Real-Time Module, NI-RIO / CompactRIO drivers, and the hardware listed in `docs/hardware/CRIO_HARDWARE_INTEGRATION.md`.
