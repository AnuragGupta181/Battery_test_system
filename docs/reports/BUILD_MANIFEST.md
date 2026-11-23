# Build Manifest: Battery Test System Simulation

## Phase 0 (2026-11-23)

### Environment
- LabVIEW: 2019 (19.0), 32-bit, `C:\Program Files (x86)\National Instruments\LabVIEW 2019\LabVIEW.exe`. It was the only installation found.
- LabVIEW MCP: v3.1.5 (9362a82e), backend `pylabview` (backendSource: call/default). The NI gRPC service was not reachable, which is expected because LabVIEW 2019 does not have it.

### Compatibility probe: FAILED
- Source: `Build/Compat_Probe/Probe_Add.xml` (a + b = sum)
- Output: `Build/Compat_Probe/Probe_Add.vi` (4305 bytes). It was written to disk, but **LabVIEW 2019 cannot open it.**
- Error: `(Hex 0x465) Error 1125: File version is later than the current LabVIEW version`
- MCP warning, quoted: "the composer writes files for LabVIEW 2020 and later only, so this VI carries the LabVIEW 2026 stamp, which LabVIEW 2019 refuses".
- The MCP helper VIs fail with the same error (set icon, and by extension exec_state and run_vi). So the MCP cannot write, check or run VIs on this station.
- Read-only file inspection (describe_project, describe_vi, describe_ctl) works, because it reads the files and needs no LabVIEW.

### Backup of originals (read-only copy, originals not touched)
`Build/Original_Backup_2026-11-23/`. The first 16 hex characters of each file's SHA256:

| File | Bytes | SHA256 (16) |
|---|---:|---|
| BATTERY TEST SYSTEM FINAL.lvproj | 94141 | 8388018C895F642C |
| user_interface.vi | 43990 | D0BA896732624737 |
| main battery tester vi22.vi | 45964 | 02B41D266C204B8C |
| main battery tester.vi | 45271 | EB0CCA6249A4EF1E |
| Stress_Calc_SubVI.vi | 6997 | D3EF465F56221625 |
| Test_State_Enum.ctl | 4368 | 5668B2005C71031E |
| Test_State_Enum2.ctl | 4301 | 1EF22623B02DA754 |
| Control 2.ctl | 3962 | 5A56427CD1089131 |
| Control 3.ctl | 4354 | 351C7A13260C66C6 |
| .aliases / .lvlps files | small | see folder |

## Route chosen by the user: guided manual build in LabVIEW 2019

### Verification channel: works
- 64-bit and 32-bit PowerShell COM fail on LabVIEW's type library: `New-Object` and `[Activator]` both raise NullReferenceException.
- **32-bit VBScript** (`C:\Windows\SysWOW64\cscript.exe`, `CreateObject("LabVIEW.Application")`) works: Version `19.0f2`, GetVIReference, SaveInstrument.
- Limitation: `VI.ExecState` returns an Automation type that VBScript can't read. The broken/run state therefore has to be checked another way, by attempting a run.

### Working copy: `Build/Simulation/`
- All project files copied. The project was renamed to `Battery_Test_System_Simulation.lvproj` (with matching .aliases/.lvlps); its relative item URLs are unchanged.
- `Battery_Test_System_Simulation.vi` was created by LabVIEW 2019 itself: it opened the copied `user_interface.vi` and saved a copy, so it is a native 2019 file with the original panel. Not yet added to the project.
- `docs/build/BUILD_GUIDE.md` is the step-by-step manual build with checkpoints.

### LabVIEW 2019 composer route: WORKS for plain VIs and typedefs (2026-11-23)
- When `aixml2vi.py` is called directly with `--lv-version 19` (the server only passes this switch for 2020 and newer), it writes files that LabVIEW 2019 opens.
- `Compat_Probe/Probe_Add_lv19.vi`: opened, ran (2+3=5, -1.5+4.25=2.75, 100+0.5=100.5) and was re-saved by LabVIEW 2019.
- Typedef route: the MCP helpers `lvtd_make_typedef.vi` and `lvai_typedef_bind.vi`, composed for 19 into `Build/Tools_LV2019/`, are run with 32-bit VBScript. LabVIEW 2019 itself then creates and saves each `.ctl`. Nested typedef links and default values are preserved (checked with describe_ctl and by reading the values back).
- Created in place: `Build/Simulation/Sim_Settings.ctl` (22 fields, demo defaults).
- Staged and verified: `Tools_LV2019/staging/Sim_Data.ctl` and `Sim_Log_Record.ctl`. `install_typedefs.ps1` recreates them in place after backing up the user's partial `Sim_Data.ctl`.
- Not yet tested on this route: event structures, formula nodes and subVI calls.
- **Installed 11:23:** `install_typedefs.ps1` created `Build/Simulation/Sim_Data.ctl` (21 fields, Active Mode → Test_State_Enum2.ctl) and `Sim_Log_Record.ctl` (State → Sim_State_Enum.ctl, Data → Sim_Data.ctl), both checked from the files. The user's partial Sim_Data.ctl (5 fields, with a stray Tab in one label) was backed up to `Tools_LV2019/staging/user_partial_Sim_Data_20261123_112350.ctl`.
- **SubVI 2.1 `Sim_Validate_Setpoints.vi` was generated, not hand-built.** Source: `Tools_LV2019/subvis/Sim_Validate_Setpoints.xml` (Index Array on a message array replaces Pick Line, which has no documented AIXML name). Composed with `--lv-version 19`, copied to `Build/Simulation/`, and its `Settings` control bound in place to `Sim_Settings.ctl` (4 link records in the file, no staging path). Tests in LabVIEW 2019 (`Tools_LV2019/tests/test_Sim_Validate_Setpoints.vbs`) passed **9/9**: valid, upper-boundary valid, I=0, I<0, V>max, C>max, D>max, all zero, small positive. Connector pane 4815: left 11/10/9/8 = V/I/C/D, 7 = Settings, right 3 = Valid?, 2 = Message.
- **SubVIs 2.2–2.5 generated, installed and tested (2026-11-23):** `Sim_Update_Model.vi` (Formula Node), `Sim_Check_Safety.vi`, `Sim_Check_Completion.vi`, `Sim_Save_CSV.vi`. Sources are in `Tools_LV2019/subvis/*.xml`. Installed by `Tools_LV2019/install_subvis.ps1`, with typedefs bound in place from the highest panel index down. Link check: each file links exactly its expected typedefs and no staging path.
  - The suite `Tools_LV2019/tests/test_subvis.vbs` passed **31/31 in LabVIEW 2019 on the installed files**:
    - Model 16: charge, discharge and idle steps, interlock, SOC clamp.
    - Safety 7: OV, OC (abs), OT, interlock, E-Stop priority, first fault time kept, injection.
    - Completion 4: not done, charge half, full cycle → Cycle Count 1, duration does not count.
    - CSV 4: header plus rows ending CRLF, enum names, unwritable path → "Save FAILED (error 8)".
  - Design choices against the guide:
    - Select nodes replace Case Structures (same behaviour).
    - Concatenate Strings plus Number To Fractional String (decimal point forced) replace multi-input Format Into String, which AIXML can't author.
    - Close File's `path` output replaces Refnum to Path.
    - `Sim_Save_CSV.vi` gained an input `File Path (empty = dialog)` so it can be tested without a dialog; the main VI leaves it unwired, which gives the dialog.
    - Clear Errors isn't needed, because the final error cluster is wired, so no automatic error dialog appears.
  - Known test-tool limits:
    - VBScript can't read a U32 (Cycle Count). The test reads it back through the CSV instead.
    - PowerShell flattens a one-item nested array (`@(,@(...))` fixes it).
  - Cosmetic: the Safety and CSV diagrams are wider than one screen (chain of 11–13 stages). The logic is unaffected; the user can tidy them with Clean Up Diagram.
- **Main VI generated (user's choice, 2026-11-23): `Build/Simulation/Battery_Test_System_Main.vi`.**
  - Source: `Tools_LV2019/main/Battery_Test_System_Main.xml`. Composed with `--lv-version 19`: 186 wires, 5 subVI calls resolved, events registered.
  - Structure: Event Structure with 8 frames (Timeout, Start, Stop, Operation Mode, Save, Reset Fault, Close, Panel Close?). State Case Structure with INIT / IDLE+STOPPED+FAULT / CHARGING+DISCHARGING / Default. Shift registers for State, Sim Data, Last Tick and Log. Bounded log feeds 3 XY graphs and the CSV.
  - Smoke test in LabVIEW 2019 over ActiveX, run async for 2.5 s then aborted: Status "Initialized. SIMULATION MODE - no hardware connected.", SOC 50, V 12, T 25, both simulated outputs OFF. Interactive tests (Part 5) are still open: latched buttons can't be pressed over ActiveX.
  - The user's old `Battery_Test_System_Simulation.vi` was left untouched.
  - Panel differences from the old UI: Charge and Discharge setpoints are two clusters (no tab control); `Operation Mode` is an enum; graphs are XY graphs. The 3 hardware LEDs are kept and always FALSE, plus a SIMULATION MODE banner.
  - **2026-11-23 12:24:** the user linked `Simulation Settings (DEMO ONLY)` → Sim_Settings.ctl, `Operation Mode` → Test_State_Enum2.ctl and `Current State` → Sim_State_Enum.ctl in the IDE. Verified: link records are in the file, and the startup run is OK (INIT → status, SOC 50, outputs OFF). Item 1 below is resolved.
  - UI styling is deferred by the user; the instructions are in `docs/build/UI_STYLING_GUIDE.md`.
  - **Not done / known:**
    1. (resolved 12:24) Main-VI controls `Simulation Settings (DEMO ONLY)`, `Operation Mode` and `Current State` are plain types identical to the typedefs, not typedef-linked. The panel-listing helper returned no rows over VBScript, so the user links them in the IDE (Replace → Select a Control).
    2. Layout helper, 2nd round (2026-11-23):
       - New tool `Tools_LV2019/panel_png.vbs` + `lv_panel_png.vi` (FP.Get Image → Write PNG File) **works**. Panel snapshots are in `Tools_LV2019/screens/`.
       - The panel Color write works.
       - Every control reference from `Controls[]` inside `lv_layout_panel.vi` is invalid (error 1055 on the first property read), tried with auto-indexing, explicit Index Array, nested `Label.Text` and `Label` → `{LV.Text}`. The same pattern works in the MCP's `lvai_typedef_tree.vi`, and the cause was not found.
       - Stopped after 4 attempts; the panel layout and Silver styling are a manual step. All attempts ran on `staging/layout_test_copy.vi`; the main VI was not touched.
       - Also: VBScript cannot index LabVIEW typed arrays (Type mismatch), so return strings instead.
    Earlier (1st round) layout helper (`Tools_LV2019/lv_layout_panel.vi`): it saved the VI, but `Controls[]` came back empty, so no control was moved. The attempt was not repeated, and the unstyled file was restored. The attempt is in `staging/Battery_Test_System_Main_layout_attempt.vi`. Panel layout and colours are a manual step.
    3. The composer gave the 5 subVIs connector pattern 4833 (16 slots), while their conIdx were written for 4815. Calls work by name, but some inputs sit on the right edge of the icon (cosmetic).
    4. The diagram is wider than one screen; Clean Up Diagram fixes that.
- Part 1 (typedefs) is complete: Sim_State_Enum (built by the user), Sim_Data, Sim_Settings, Sim_Log_Record, and Test_State_Enum2 (reused).

### Cleanup (2026-11-23, user's choice "group A only")
Deleted as never used: in no project, and no VI references them (checked with a binary search of every .vi/.ctl):
- `Control 2.ctl`, `Control 3.ctl` and `main battery tester.vi` (the older version of `main battery tester vi22.vi`), in the root, `Build/Simulation` and the backup folder.
- The failed layout experiment `Tools_LV2019/lv_layout_panel.xml`, `layout_panel.vbs` and `panel_tree.vbs`.

All of these remain retrievable from git history (commit `7620acf` and earlier). The hashes in the tables above are kept for the record.

During the cleanup, `Build/Original_Backup_2026-11-23/` and the root `main battery tester vi22.vi` were found deleted from disk outside the cleanup command. They were restored unchanged from git (vi22 hash `02B41D266C204B8C` verified).

### Docs reorganised (2026-11-23)
- `PROJECT_PROMPT.md` → `docs/requirements/`
- Conference paper PDF → `docs/reference/Stress_Aware_Battery_Test_Conference_Paper.pdf` (renamed; original name `Stress_Aware_Battery_Test_Conference_Paper_FIMO_Format_2004_corrected (1) (1).pdf`)
- `BUILD_GUIDE.md` → `docs/build/` (it was in `Build/Simulation/`)
- `BUILD_MANIFEST.md` → `docs/reports/` (it was in `Build/`)

### Findings from the original files (read with pylabview, no LabVIEW)
- `Test_State_Enum.ctl` holds 8 items (INIT, IDLE, CHARGE _CC, CHARGE _CV, REST, DISCHARGE_DC, Fault, Stop), not the 6 in the brief. It was left unchanged, and a new `Sim_State_Enum.ctl` is planned.
- `Test_State_Enum2.ctl` is the Charge/Discharge mode typedef. It is reused.
- `user_interface.vi`: almost the whole diagram sits in the Disabled frame of a Diagram Disable structure. The only live code was Random Number (U64) → the DC Voltage/DC Current charts. Three labels each appear twice (DC Voltage, DC Current, Temperature). The blank field next to Close is a string indicator labelled `Clock`.

## Hardware plan revised (2026-11-23)
- `docs/hardware/CRIO_HARDWARE_INTEGRATION.md` was rewritten as a low-cost bench: 4 × 18650 2000 mAh cells in series (4S) with a balancing BMS, a fixed 16.8 V / 1 A charger, a 12 V 10 W bulb + 4.7 Ω load, a 0.05 Ω shunt, one type K thermocouple and a 2-channel relay module (≈ ₹1,600–2,400; the cRIO and its modules are already in the lab).
- Removed from the plan: programmable supply and electronic load, contactors, the second (ambient) thermocouple, the NI 9205 divider and the NI 9263 setpoints. All measurements are on NI 9219; NI 9401 drives the two relays.
- README and BUILD_AND_TEST_REPORT §7 were updated to match.
