# Battery Test System: Simulation Phase

A LabVIEW 2019 battery charge/discharge test application for an NI cRIO-9063 (modules NI 9205, 9219, 9263 and 9401).
**The current phase is simulation only.** No physical I/O, no cRIO deployment, no power supply or load.
The full requirements are in `docs/requirements/PROJECT_PROMPT.md`.

## Folder layout
```
/                                   ORIGINAL project - never modify
  BATTERY TEST SYSTEM FINAL.lvproj    (LVVersion 19008000)
  user_interface.vi                   original UI (cRIO target); most of its diagram is disabled
  main battery tester vi22.vi         cRIO RT VI
  Stress_Calc_SubVI.vi
  Test_State_Enum.ctl                 8 items (INIT, IDLE, CHARGE _CC, CHARGE _CV, REST, DISCHARGE_DC, Fault, Stop) - used by RT VI
  Test_State_Enum2.ctl                Charge / Discharge mode typedef
  Control 2.ctl, Control 3.ctl, main battery tester.vi   on disk, not in the project
Build/
  Original_Backup_2026-11-23/         byte copy of the originals (SHA256 values in the manifest)
  Compat_Probe/                       failed MCP probe for LabVIEW 2019 - kept as evidence
  Simulation/                         WORKING COPY - all new work goes here
    Battery_Test_System_Simulation.lvproj
    Battery_Test_System_Simulation.vi  starting VI (copy of user_interface.vi, saved by LabVIEW 2019)
docs/
  requirements/   what to build
  build/          how to build it
  reports/        what was done and verified
  reference/      background material
```

## Docs by use
| Use | File |
|---|---|
| Requirements, acceptance criteria and safety rules | `docs/requirements/PROJECT_PROMPT.md` |
| Step-by-step manual build (typedefs, subVIs, panel, diagram, tests) with checkpoints | `docs/build/BUILD_GUIDE.md` |
| Optional manual Silver UI styling of the main VI (when the user wants it) | `docs/build/UI_STYLING_GUIDE.md` |
| Build log: environment, compatibility probe result, backups, file hashes, findings | `docs/reports/BUILD_MANIFEST.md` |
| Test results: unit 41/41, acceptance 15/15, fixed defects, limitations | `docs/reports/BUILD_AND_TEST_REPORT.md` |
| Future hardware: parts list, module/channel/pin wiring, software steps, bring-up order | `docs/hardware/CRIO_HARDWARE_INTEGRATION.md` |
| Project overview and quick start for humans | `README.md` (root) |
| Background: stress-aware battery test paper | `docs/reference/Stress_Aware_Battery_Test_Conference_Paper.pdf` |

Keep this structure. New test results go in `docs/reports/` (for example `BUILD_AND_TEST_REPORT.md`), and the end-user README goes in `docs/build/` or at the top of `Build/Simulation/`. Record every new or moved file in the manifest.

## Hard rules
1. **LabVIEW 2019 (19.0f2, 32-bit) only.** Do not upgrade, retarget, or change `LVVersion` or version stamps.
2. **Never modify the original files in the root.** Work in `Build/Simulation/` only.
3. **No physical I/O** (DAQmx, FPGA, Scan Engine, cRIO) in the simulation path. Never deploy to the cRIO.
4. Every simulated limit and value is DEMONSTRATION ONLY. Never present it as a real Li-ion safety limit.
5. Never claim a VI works without running it in LabVIEW 2019. Report failures exactly.

## Tooling facts (measured 2026-11-23)
- **The LabVIEW MCP (Zuehlke, v3.1.5, pylabview backend) cannot write VIs for LabVIEW 2019.** The composer stamps files for 2020 and later, so 2019 returns `Error 1125: File version is later`. Its helper VIs (exec_state, run, icon) fail the same way. NI's gRPC service does not exist in 2019.
  - **Do not use** MCP generate, convert, run or exec_state tools against this station.
  - **Read-only MCP tools work**, because they read the files without LabVIEW: `lvai_describe_project`, `lvai_describe_vi`, `lvai_describe_ctl`. Use them to verify what the user saved at each checkpoint.
- **Working LabVIEW 2019 route (measured):** run the composer directly with `--lv-version 19`:
  `bin\pylabview\python.exe bin\scripts\aixml-pylabview\aixml2vi.py <in.xml> <out.vi> --lv-version 19 --labview-root "C:\Program Files (x86)\National Instruments\LabVIEW 2019"`.
  - Plain VIs load and run in 2019.
  - Typedefs are made by the 2019-composed helpers in `Build/Tools_LV2019/` (`make_typedef.vbs`, `bind_typedef.vbs`, `read_ctl_value.vbs`), so LabVIEW 2019 saves them itself.
  - Event structures, formula nodes and subVI calls are not yet tested on this route.
  - **SubVI recipe** (proven on `Sim_Validate_Setpoints.vi`, 9/9 tests):
    1. Author `Tools_LV2019/subvis/<name>.xml` with typedef inputs written as plain clusters or enums of the identical type, and run `lvai_check_aixml`.
    2. Compose with `--lv-version 19` and copy to `Build/Simulation/` (never overwrite).
    3. Bind each typedef control **in place** with `bind_typedef.vbs <vi> - <panelIndex> <ctl>` (`-` = the panel itself). Binding in staging leaves relative links pointing at the wrong folder.
    4. Test with a VBScript in `Tools_LV2019/tests/`.
  - Pick Line has no documented AIXML name, so use Index Array on a string-array constant instead.
  - In PowerShell 5.1, an empty-string argument to a native exe is dropped. Use `-` as the placeholder.
  - When binding several typedefs in one VI, go from the **highest panel index down** (`install_subvis.ps1`).
  - Formula Node: `<Node _name="Formula Node" text="...one line...">`, with variables as terminals. This works on the 2019 route.
  - Format Into String takes only ONE input in AIXML. Build strings with Concatenate Strings and Number To Fractional String (`use system decimal point` = FALSE).
  - Test-script limits: VBScript can't read U32 values (read them via CSV), and a one-item nested array in PowerShell needs `@(,@(...))`.
- **All 5 subVIs are done and tested (31/31 + 9/9):** `Tools_LV2019/tests/test_subvis.vbs <folder> <scratch>` and `test_Sim_Validate_Setpoints.vbs`.
- **Otherwise the build is manual:** the user follows `docs/build/BUILD_GUIDE.md` in LabVIEW 2019, and Claude checks the files after each checkpoint.
- **Driving LabVIEW 2019 from scripts:** use **32-bit VBScript** only: `C:\Windows\SysWOW64\cscript.exe //nologo script.vbs` with `CreateObject("LabVIEW.Application")`.
  - Confirmed working: `Version`, `GetVIReference(path, "", False, 0)`, `SaveInstrument path, saveCopy, False`, `.Name`.
  - `VI.ExecState` cannot be read from VBScript (unsupported Automation type), so detect a broken VI by attempting a run.
  - PowerShell COM (32- or 64-bit, `New-Object` or `[Activator]`) fails with NullReferenceException. Don't use it.
  - `SetControlValue` does not fire Value Change events, so the user clicks buttons during tests while the script polls indicators.
- An enum indicator may not be readable from VBScript. Read `Status Message` and the numeric indicators instead.

## Simulation design (summary; details in BUILD_GUIDE)
- **Main VI:** one While Loop with an Event Structure (timeout from settings, default 200 ms). Then a state Case Structure, then `Sim_Update_Model.vi`, then `Sim_Check_Safety.vi`, then FAULT override.
- **Shift registers:** State, Sim Data, Last Tick, Log.
- **States** (`Sim_State_Enum.ctl`): INIT, IDLE, CHARGING, DISCHARGING, STOPPED, FAULT.
- **Time step:** dt is measured with Tick Count and capped at `Max dt`.
- **SOC model:** `dSOC = C-rate * 100 * dt * SpeedFactor / 3600` (idealized). V and I approach their setpoints first-order. Temperature heats with I² and cools first-order to ambient.
- **Output interlock:** enforced in the model. Only CHARGING enables the supply, and only DISCHARGING enables the load.
- **Safety priority:** E-Stop, then overvoltage, then overcurrent, then overtemperature, then interlock. Faults latch until Reset Fault, and the reset only holds if the cause is gone.
- **Cycle count:** a half-cycle counts only when its SOC target is reached. Duration expiry, Stop and Fault don't count.
- **CSV:** Save writes the last `History Length` samples, after a confirm-overwrite file dialog.
- `Sim_Update_Model.vi` is the hardware abstraction point. A later cRIO phase replaces it.

## Current status (updated 2026-11-23, after acceptance tests)
- **All acceptance tests passed in LabVIEW 2019** (see BUILD_AND_TEST_REPORT.md). Two defects were found and fixed (Save dialog; latched-fault status text).
- To re-run interactive tests: `Build/Tools_LV2019/tests/monitor_main.vbs <main.vi> <log> [minutes]` runs the VI with its panel open and logs indicator changes. The operator clicks; Close ends it.
- Still open, and optional: Silver UI (manual, guide in docs/build), cosmetic pane pattern and diagram width.

## Status before acceptance tests
- **Generated and running in LabVIEW 2019:** all typedefs, 5 subVIs (40/40 tests), and the main VI `Build/Simulation/Battery_Test_System_Main.vi` (smoke-tested only). See the manifest for what is still open: typedef links on 3 main-VI controls, panel layout and colours (manual), subVI pane pattern (cosmetic), and the interactive Part 5 tests.
- Known VBScript blind spots: U32 values, Boolean arrays, enum-valued properties. Panel `Controls[]` read through a composed helper came back empty and was not resolved, so don't retry it blindly.

## Earlier status
- Phase 0 is done: compatibility probe (failed, documented), backup, working copy.
- The user is building Parts 1–4 of `docs/build/BUILD_GUIDE.md`. When they report "Part N done", verify those files with the read-only MCP tools and VBScript.
- Open question for the user: did they intend to save a 6-state `Test_State_Enum.ctl`? The saved file has 8 items.
