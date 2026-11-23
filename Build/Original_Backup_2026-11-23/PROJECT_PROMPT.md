# Project Prompt: Battery Test System Simulation and LabVIEW VI Development

> **Purpose:** Give this document, the existing LabVIEW project, and the attached screenshots to an AI coding agent that has access to the Zuehlke LabVIEW MCP server. The agent must inspect the real project, create a working LabVIEW `.vi`, and verify it in the installed LabVIEW 2019 environment. This is an implementation task, not a request for a conceptual diagram or pseudocode.

---

## 1. Role and Overall Mission

Act as a **senior LabVIEW developer and automation test engineer** with practical experience in LabVIEW 2019, CompactRIO, event-driven state machines, simulation, front-panel design, and LabVIEW VI debugging.

You have access to:

- The user's existing LabVIEW project and VIs.
- A Windows machine with LabVIEW 2019 installed.
- The Zuehlke LabVIEW MCP repository/server: <https://github.com/Zuehlke/labview-mcp>.
- The user's screenshots of the existing Front Panel, Block Diagram, Project Explorer, Enum typedef, cRIO modules, and hardware connectors.

Your mission is to finish the **software logic and simulation version** of the user's Battery Test System. Improve the existing Front Panel rather than replacing it with an unrelated design. Generate and deliver a real, loadable, executable LabVIEW `.vi` file, along with any required typedefs and supporting VIs.

The first development target is **LabVIEW 2019**. Do not upgrade LabVIEW, retarget the project to a newer LabVIEW version, or silently produce a newer-version VI. The cRIO hardware is intended to remain compatible with the user's LabVIEW 2019 installation.

The immediate deliverable is a **simulation-only working application**. Do not require a physical battery, shunt resistor, thermocouple, power supply, electronic load, or physical I/O wiring for this phase.

### Definition of done

The task is complete only when:

1. A real `.vi` file has been created or safely updated in the working project copy.
2. The `.vi` opens in **LabVIEW 2019** without a version error or corruption warning.
3. The VI has no broken-run arrow and no broken wires or missing subVIs.
4. The Front Panel is usable and is based on the supplied existing UI.
5. Start, Charge, Discharge, Stop, Reset/Fault handling, Save, and Close behave correctly in simulation.
6. Voltage, current, temperature, SOC, cycle count, elapsed time, status, and graphs update from simulated data.
7. CSV logging produces a valid file with headings and data rows.
8. The agent has actually executed the VI in LabVIEW 2019 and recorded the test results. Static XML validation alone is not sufficient.
9. The original project and original VIs remain recoverable and unmodified unless the user explicitly approves a change to them.

Do not claim that a VI works merely because an MCP generation call returned success. Open, inspect, run, and test it in LabVIEW 2019.

---

## 2. Critical Compatibility Gate: LabVIEW 2019 + LabVIEW MCP

Repository: <https://github.com/Zuehlke/labview-mcp>

Read the repository's current README and these guides before using write tools:

- README: <https://github.com/Zuehlke/labview-mcp>
- Safety: <https://github.com/Zuehlke/labview-mcp/blob/main/docs/guide/safety.md>
- Tool catalogue: <https://github.com/Zuehlke/labview-mcp/blob/main/docs/guide/tools.md>
- AIXML workflow: <https://github.com/Zuehlke/labview-mcp/blob/main/docs/guide/aixml-workflow.md>
- AIXML backend details: <https://github.com/Zuehlke/labview-mcp/blob/main/docs/aixml-backends.md>

**Do not assume that MCP support for LabVIEW 2019 is established.** The current repository describes LabVIEW 2020 as the oldest tested release. Its backend notes also warn that the current `pylabview` composer has version-specific limitations before LabVIEW 2020. LabVIEW 2019 therefore needs an explicit compatibility experiment before real project files are touched.

### Required compatibility test

1. Discover the tools actually exposed by the installed MCP server. Do not invent tool names or parameters.
2. Run the available status/installation checks, such as `lvai_status`, `pylv_status`, and `lvai_list_labview_installations` if those exact tools are exposed by the installed server.
3. Confirm that the server detects the actual LabVIEW 2019 installation, its executable path, bitness, and the backend it intends to use.
4. Read the MCP backend documentation. For older LabVIEW versions, the repository describes the `pylabview` route and LabVIEW ActiveX/VI Server usage; do not assume the NI gRPC service is available in LabVIEW 2019.
5. Create a **disposable compatibility probe** in a new scratch directory, not in the original project. It should be a very small VI with a numeric control, an Add node, and a numeric indicator.
6. Use the backend explicitly when appropriate. Record the actual backend selected and the `backendSource` returned by the tool, if supplied.
7. Open the generated probe in LabVIEW 2019, save it from LabVIEW 2019, confirm its block diagram, confirm its execution state, and run it with at least two known inputs.
8. Test a small event-driven probe only after the basic VI probe passes.
9. Keep the complete probe files and results in the build report.

### If the compatibility test fails

- Stop before modifying the user's actual project files.
- Do not use a newer LabVIEW version to create a VI and then present it as a LabVIEW 2019 deliverable.
- Do not silently change project `LVVersion` metadata or binary version stamps.
- Do not say that LabVIEW 2019 is supported just because a `.vi` file was written to disk.
- Report the exact failing step and error.
- Investigate whether the installed MCP version has a documented LabVIEW 2019-compatible route, or whether LabVIEW 2019's own VI Server/ActiveX or native LabVIEW tools can complete the operation safely.
- If no verified route exists, stop and give the user a clear choice before changing versions or using an alternate workflow. **Do not upgrade LabVIEW without the user's permission.**

The user's priority is LabVIEW 2019 compatibility because the cRIO system is already configured around that environment.

---

## 3. Safety, Backups, and File Handling

The MCP repository explicitly describes itself as research-grade and warns that write operations can overwrite or damage VIs. Follow these rules:

1. Locate the real project folder and inspect its contents before doing anything.
2. Create a complete working copy of the project before any mutation. Preserve the directory structure and dependencies.
3. Keep the original `.lvproj`, original `.vi` files, and original `.ctl` files unchanged.
4. Work under a new folder such as `Build/Simulation/` or another clearly named copy of the project.
5. Use new VI names for generated files. Do not overwrite `user_interface.vi`, `main battery tester vi22.vi`, `Stress_Calc_SubVI.vi`, or either Enum typedef in the original project.
6. Before every destructive MCP operation, state which file it will modify and confirm that the target is a working copy.
7. Do not allow-list every MCP write tool. Keep mutation confirmation enabled.
8. Do not deploy code to the cRIO, write to NI 9205/9219/9263/9401 channels, or communicate with a power supply/load in this phase.
9. Do not run any VI that might access physical I/O. The simulation VI must be isolated from physical I/O calls.
10. Record backups and generated files in a build manifest.

The final output should include the original project untouched plus the completed simulation project copy.

---

## 4. Existing Project and Known Files

The user has supplied a Project Explorer screenshot showing a project named:

`BATTERY TEST SYSTEM FINAL.lvproj`

The project tree visibly contains:

### My Computer target

- `Test_State_Enum.ctl`
- `Test_State_Enum2.ctl`
- Dependencies
- Build Specifications

### cRIO target

- `NI-cRIO-9063-01bc8d3c` (the IP shown in the screenshot was `10.10.149.196`; do not hard-code this IP because it may change)
- Chassis: `cRIO-9063`
- Real-Time Scan Resources:
  - `Mod1 (Slot 1, NI 9205)`
  - `Mod2 (Slot 2, NI 9219)`
  - `Mod3 (Slot 3, NI 9263)`
  - `Mod4 (Slot 4, NI 9401)`
- `main battery tester vi22.vi`
- `Stress_Calc_SubVI.vi`
- `user_interface.vi`
- Dependencies including random-number VIs and `Test_State_Enum.ctl`

The exact paths, target ownership, VI properties, typedef references, and current broken/run states must be discovered from the actual project. Treat the screenshot as a guide, not a replacement for inspecting the files.

### Existing Enum typedef

The user initially had an Enum containing only `INIT`. The user later added all six state values and confirmed that all six cases now appear in the Case Structure. Inspect the actual saved typedef before changing it.

The intended main state list is:

1. `INIT`
2. `IDLE`
3. `CHARGING`
4. `DISCHARGING`
5. `STOPPED`
6. `FAULT`

Use one canonical state typedef, preferably the existing `Test_State_Enum.ctl` if the references are correct. Investigate `Test_State_Enum2.ctl` and all references before deciding whether it is duplicate or in use. Do not delete or rename it without evidence and user approval.

---

## 5. Hardware Inventory (Future Integration Only)

The user has a real NI cRIO-9063 system with these modules, confirmed by the Project Explorer and module photographs:

| Hardware | Slot | Intended future role | Important notes |
|---|---:|---|---|
| NI cRIO-9063 | Chassis | Real-Time controller | Existing project target |
| NI 9205 | 1 | Analog voltage input | Intended for battery voltage sensing through a properly designed input/scaling circuit |
| NI 9219 | 2 | Universal analog input | Intended for thermocouple and shunt-voltage sensing, subject to sensor wiring and input mode/range |
| NI 9263 | 3 | Analog voltage output | Possible future low-level analog reference to a compatible power supply; not a power driver |
| NI 9401 | 4 | Digital I/O | Possible future enable/status signals through suitable isolation/driver circuitry |

The battery pack is described by the user as a **12 V lithium-ion battery pack**, but its exact cell configuration and chemistry details have not been confirmed. The shunt resistor value/rating, thermocouple type, power supply model, electronic load model, and full electrical interface specifications are also not confirmed.

### Hardware restrictions for this phase

- No battery is currently available for testing.
- No shunt resistor is currently available for testing.
- No real thermocouple setup is being used for this phase.
- Do not create actual DAQmx, FPGA, Scan Engine, or cRIO I/O read/write calls in the active simulation path.
- Do not assume that a virtual Boolean represents a real NI 9401 physical pin.
- Do not assume a 12 V nominal pack is a particular series count or chemistry-specific voltage range.
- Do not hard-code real battery charge limits, current limits, temperature limits, or safety claims.
- Add a clear `SIMULATION MODE` indication to the UI.
- In simulation mode, physical connection indicators must not falsely report connected hardware. Show `Simulation` or `Not Connected` status clearly.

Design a clean hardware abstraction boundary so that a later hardware phase can replace simulated sensor sources and simulated outputs with real cRIO I/O subVIs. That future phase is out of scope now.

---

## 6. Current Front Panel: Preserve and Improve It (Option B)

The user selected **Option B: improve the existing UI**, not a completely unrelated redesign.

The supplied Front Panel screenshot shows a dark/black battery-monitoring interface with:

### Existing controls and indicators

- `DAQ CONNECTED?` Boolean indicator
- `Power Supply Connected?` Boolean indicator
- `DC Load Connected?` Boolean indicator
- `Cycle` display
- `DC Voltage` numeric indicator
- `DC Current` numeric indicator
- `Temperature` numeric indicator
- `Save` button
- `Stop` button
- `Close` button
- `Start` button
- `Select Function` area with `Charge` and `Discharge` choices/buttons
- A tab control with `Charge` and `Discharge` tabs
- Charge settings visible in the screenshot:
  - `Charging Voltage`
  - `Charge Current`
  - `C-Rate`
  - `Charge Duration`
- Existing block diagram references also show controls/indicators with names similar to `DisCharging Voltage 2`, `Charge Duration 2`, `Charge Current 2`, `Temperature`, and related discharge values. Inspect the actual Front Panel to find the real controls and labels; do not blindly rename or replace them.
- Three graph/chart areas:
  - DC Voltage versus Time
  - DC Current versus Time
  - Temperature versus Time
- Existing graph plot selectors/toolbars are visible in the screenshot.
- A blank status/message field is visible near the Save/Stop/Close controls.

### UI design goals

Improve the existing screen while keeping its familiar arrangement and interaction model:

- Keep a professional industrial test-instrument appearance.
- Keep the current dark theme, but improve alignment, spacing, readable contrast, typography, group boundaries, and visual hierarchy.
- Keep Start/Stop/Save/Close easy to find.
- Make Charge and Discharge selection clear and unambiguous.
- Organize Charge and Discharge parameters into clean tab pages or grouped panels.
- Keep the three live plots visible and properly labelled with units.
- Make the status area useful: current state, simulation mode, operation status, warnings, and saved-file messages.
- Show SOC (%) clearly. Add a numeric SOC indicator and preferably a simple progress/bar indicator if compatible with LabVIEW 2019.
- Show elapsed operation time and cycle count clearly.
- Show `SIMULATION MODE` prominently so no operator mistakes simulated data for real measurements.
- Add a `Reset Fault` button if needed for the FAULT state.
- Add configurable simulation-only limits/settings where needed, clearly labelled as demonstration settings rather than real battery safety limits.
- Use native LabVIEW 2019 controls and indicators unless the installed environment proves an add-on is available. Do not introduce dependencies on newer NXG controls or unsupported packages.
- Preserve existing control types, labels, terminal references, typedef bindings, and interaction behavior wherever practical. If a control must be replaced, map it explicitly and verify all references.
- Do not sacrifice working controls just to make the panel look different.

### Suggested screen layout

1. **Top status strip:** Simulation Mode, current state, DAQ/hardware state, power supply/load status, cycle count, elapsed time.
2. **Left control column:** Select Charge/Discharge, Start, Stop, Reset Fault, Save, Close.
3. **Center settings panel:** Charge and Discharge tabs with validated numeric settings and units.
4. **Right monitoring panel:** DC Voltage, DC Current, and Temperature charts.
5. **Bottom status/message area:** State transition messages, input validation messages, fault reason, file-save result.

Use the existing panel dimensions and screenshot as the starting point. Do not redesign from scratch unless the existing VI is technically unusable, in which case report why and preserve a copy of the original panel.

---

## 7. Application Behaviour and Functional Requirements

Build a simulation-first battery test application with these modes:

- `IDLE`
- `CHARGING`
- `DISCHARGING`
- `STOPPED`
- `FAULT`

Use `INIT` only for startup initialization.

### User interaction

- The user selects Charge or Discharge.
- The user enters mode-specific setpoints and test duration.
- Pressing Start validates the inputs and starts the selected mode.
- Stop stops the active operation and immediately sets both simulated output enables to OFF.
- Reset Fault clears a latched fault only if the simulated fault condition has been removed and reset is allowed.
- Save writes the collected simulation data to a CSV file.
- Close safely stops the loop, sets both simulated outputs OFF, closes file references, and exits.
- Changing the selected mode while an operation is active must not silently switch the running operation. Either ignore the mode change with a status message or require Stop first.

### Input validation

Before starting an operation, validate all values used by that mode:

- Numeric values must be finite and within configured simulation ranges.
- Required voltage/current/C-rate/duration settings must be greater than zero if required by the selected mode.
- Duration must have a clear unit (prefer minutes in the UI, but inspect existing controls and standardize labels consistently).
- Reject NaN, infinity, negative values, and impossible combinations.
- Do not start if validation fails. Keep outputs OFF and display a useful message.
- Make sure `Charge` and `Discharge` modes use the correct settings from their own tab.

### Charge simulation

During CHARGING:

- Simulated power-supply enable = TRUE.
- Simulated DC-load enable = FALSE.
- Update SOC upward, bounded to 0–100%.
- Simulate battery voltage approaching the configured charge-voltage setpoint using a documented, configurable demonstration response.
- Simulate battery current approaching the configured charge-current setpoint using a documented, configurable demonstration response.
- Simulate temperature with a simple configurable heating/cooling model. Label it as simulated, not measured.
- Increase elapsed time based on actual elapsed loop time or a measured delta-time, not by assuming that every loop iteration always took exactly 200 ms.
- Stop normally when SOC reaches the configured simulated completion level (100% by default) or the selected duration expires.
- A manual Stop must stop immediately and must not count as a completed cycle.

For an idealized demonstration of C-rate progression, the agent may use:

`SOC_delta_percent = C_rate * 100 * delta_time_seconds / 3600`

This is a simplified ideal model, not a validated electrochemical battery model. Document the assumption and make the model easy to replace.

### Discharge simulation

During DISCHARGING:

- Simulated power-supply enable = FALSE.
- Simulated DC-load enable = TRUE.
- Update SOC downward, bounded to 0–100%.
- Simulate voltage/current responses using configurable demonstration behaviour and the Discharge tab inputs.
- Simulate temperature using the same documented demonstration thermal model.
- Increase elapsed time using measured delta-time.
- Stop normally when SOC reaches the configured lower completion level (0% by default) or the selected duration expires.
- A manual Stop must stop immediately and must not count as a completed cycle.

### Cycle-count definition

Define cycle counting explicitly. A recommended definition is:

- Mark the charge half-cycle complete only when the configured charge completion condition is reached.
- Mark the discharge half-cycle complete only when the configured discharge completion condition is reached.
- Increment Cycle Count once when a complete charge-plus-discharge pair has finished.
- Do not increment the cycle count on manual Stop, a partial cycle, or a Fault.

Document this definition in the UI/help text or project documentation.

### Safety/interlock simulation

All safety checks in this phase are software simulation checks only. They are not a substitute for a battery management system, certified protection, hardware interlock, or independent emergency-stop circuit.

Implement a priority-ordered safety check for:

1. Simulated emergency-stop/fault injection.
2. Simulated overvoltage.
3. Simulated overcurrent.
4. Simulated overtemperature.
5. Invalid or conflicting operation requests.
6. Mutually exclusive output commands.

On any fault:

- Transition to FAULT.
- Set simulated power-supply enable = FALSE.
- Set simulated DC-load enable = FALSE.
- Preserve a fault code/reason and timestamp.
- Show a visible warning and useful explanation.
- Latch the fault until a valid Reset Fault action.

Because the battery chemistry/series configuration and sensor hardware are not confirmed, do **not** claim that any demo threshold is a valid lithium-ion safety limit. Add clearly labelled configurable `Simulation Limits` values and/or fault-injection controls. Any default test values must be identified in code and UI as demonstration-only.

### Output interlock

At all times:

- Power Supply Enable and DC Load Enable must never both be TRUE.
- IDLE, STOPPED, INIT, and FAULT require both outputs OFF.
- CHARGING may enable only the simulated power-supply output.
- DISCHARGING may enable only the simulated DC-load output.
- Enforce this in a central output-decision function or state-output section, not just through UI button appearance.

---

## 8. Recommended LabVIEW Architecture

Use a straightforward, maintainable LabVIEW 2019 architecture. Do not introduce an unnecessarily complicated DQMH, Actor Framework, or LabVIEW class hierarchy for this first simulation unless the existing project already depends on it.

### Main VI

Use the existing `user_interface.vi` as the UI reference and likely supplied-panel source. Prefer a new simulation VI name, such as:

`Battery_Test_System_Simulation.vi`

The agent must inspect whether the existing `user_interface.vi` is under the cRIO target or My Computer. Because this phase must run without physical I/O, create or place the simulation VI under **My Computer** if that is the safest architecture. Keep the existing cRIO target and original RT VI files unchanged for future hardware integration.

If the current UI VI is only under the cRIO target, make a working copy for the desktop simulation. Preserve the original front panel and all control meanings. Do not move the original VI across targets in place.

### Main loop design

Use one main While Loop with:

- An Event Structure with a 200 ms timeout (or a clearly documented configurable UI refresh interval).
- A state Enum shift register.
- A simulation-data cluster shift register.
- Any small additional shift registers required for mode, log state, and timing.
- An Enum Case Structure for state execution.
- A clean Stop/Close path.

Avoid creating multiple uncontrolled parallel While Loops for the same state or UI values.

### Event Structure events

At minimum handle:

- Start Button: Value Change
- Stop Button: Value Change
- Select Function / Mode: Value Change
- Save Button: Value Change
- Reset Fault: Value Change
- Close Button: Value Change
- Timeout

Every Event Structure output tunnel must be wired in every event case, or have a deliberately selected default value where valid. Preserve the state in events that do not request a transition.

Suggested event behaviour:

| Event | Requested state/action |
|---|---|
| Timeout | Pass current state through; execute one simulation update |
| Start | Validate selected mode and inputs; request CHARGING or DISCHARGING |
| Stop | Request STOPPED |
| Select Function | Update selected mode only when not running; otherwise show a message |
| Save | Write current/collected log data; preserve current state |
| Reset Fault | Clear FAULT only after reset validation; request IDLE |
| Close | Request safe stop, close resources, then stop the While Loop |

If the user interface uses momentary buttons, configure mechanical action correctly for Event Structure Value Change handling. Do not leave a latching button latched because the event case never reads/resets it.

### State Case Structure

Use one Case Structure driven by the state Enum:

| State | Required behaviour | Next state |
|---|---|---|
| INIT | Initialize simulation values, histories, timers, output flags, log state | IDLE |
| IDLE | Keep both outputs OFF; wait for Start; preserve SOC and measurements | IDLE until event requests a start |
| CHARGING | Run charge simulation, update SOC/voltage/current/temperature, evaluate faults and completion | CHARGING, STOPPED, or FAULT |
| DISCHARGING | Run discharge simulation, update SOC/voltage/current/temperature, evaluate faults and completion | DISCHARGING, STOPPED, or FAULT |
| STOPPED | Force both outputs OFF, preserve current SOC and last measurements, prepare for a new start | STOPPED until a valid Start or Reset action |
| FAULT | Force both outputs OFF, latch fault information, prevent start | FAULT until valid Reset Fault action |
| Default | Safe fallback: outputs OFF, record unexpected state, go to FAULT | FAULT |

Do not make STOPPED immediately become IDLE in a way that loses the visible stopped indication. A new Start may transition from STOPPED after validation.

### State/wire order

Use a consistent data flow:

1. Left state shift-register terminal provides the current state.
2. Event Structure receives UI events and outputs the requested state/action.
3. The state-machine Case Structure executes the selected state logic.
4. Each state case outputs the next state and updated simulation-data cluster.
5. The right state shift-register terminal receives the next state.
6. UI indicators and charts are updated from the resulting simulation-data values.
7. The While Loop stop terminal receives the safe Close/Stop condition.

The exact implementation may use command enums or a command cluster if that is cleaner, but maintain a single clear source of truth for the state and avoid duplicated state variables.

### Typedefs/clusters

Reuse existing typedefs where correct. If needed, create clean typedefs such as:

- `Test_State_Enum.ctl`: INIT, IDLE, CHARGING, DISCHARGING, STOPPED, FAULT.
- `Operation_Mode.ctl`: CHARGE, DISCHARGE.
- `Simulation_Data.ctl` cluster containing SOC, simulated voltage, simulated current, simulated temperature, elapsed time, cycle count, simulated power-supply enable, simulated DC-load enable, fault flag/code/reason, and cycle-half completion flags.
- `Simulation_Config.ctl` cluster containing simulation response rates and clearly labelled demo limits.
- `Log_Record.ctl` cluster for each logged sample, if using a record-based logger.

Use Bundle by Name / Unbundle by Name where practical. Use correct data types consistently (DBL for engineering-style simulated values; U32 or integer for cycle count; Boolean for flags; string for messages). Do not introduce duplicate typedefs without a reason.

---

## 9. Data Simulation and UI Updates

Simulation must be deterministic enough to test and visually smooth enough to demonstrate the system. Do not use random noise as the only behaviour. Random variation may be added as a small optional, bounded display noise after the base model works.

### Initial simulation values

Use clearly labelled demo starting values such as:

| Parameter | Demo start value | Note |
|---|---:|---|
| SOC | 50% | Demonstration starting condition |
| Voltage | 12.0 V | Nominal placeholder only; not a confirmed pack voltage curve |
| Current | 0.0 A | No operation at startup |
| Temperature | 25.0 °C | Demonstration ambient/start temperature |
| Cycle Count | 0 | No completed cycles |
| Power Supply Enable | FALSE | Safe idle state |
| DC Load Enable | FALSE | Safe idle state |
| Fault | FALSE | No fault at startup |

The user stated that the pack is 12 V nominal, but its cell configuration is unknown. Do not use the 12.0 V display placeholder to infer a valid max charge voltage.

### Time step

The Event Structure timeout is a UI scheduling target, not a guarantee that every loop iteration takes exactly 200 ms. Use a LabVIEW timing function such as `Tick Count (ms)` or a suitable elapsed-time mechanism to calculate actual `delta_time_seconds`. Clamp an anomalously large delta after a pause/dialog so one UI stall cannot cause an unrealistic SOC jump.

### SOC

For a simplified ideal C-rate model:

`SOC_delta_percent = C_rate * 100 * delta_time_seconds / 3600`

- Add it during CHARGING.
- Subtract it during DISCHARGING.
- Clamp SOC between 0 and 100.
- Clearly label this as an idealized simulation, not a battery chemistry model.

### Voltage, current, and temperature

- Use the user's charge/discharge setpoints as simulation inputs.
- Implement a configurable, bounded response (for example, a first-order or slew-limited response) so charts show a smooth transition toward setpoints.
- Use explicit simulation coefficients stored in `Simulation_Config.ctl`; do not bury unexplained magic numbers inside the block diagram.
- Use a simple documented thermal response with ambient cooling and current-related heating.
- Keep all simulated data visibly identified as simulation data.
- Keep the model modular so a later hardware implementation can replace the simulation update VIs/subVIs without redesigning the UI/state machine.

### Graphs

Update the existing three graphs/charts:

1. DC Voltage (V) versus Time (s)
2. DC Current (A) versus Time (s)
3. Temperature (°C) versus Time (s)

Keep a bounded history buffer so long runs do not grow memory without limit. Use the correct chart/graph data type and LabVIEW 2019-supported property/node approach. Do not invent property names; query the palette/API or inspect a working example.

### Other indicators

Update:

- DC Voltage
- DC Current
- Temperature
- SOC
- Cycle Count
- Elapsed Time
- Current State / Mode
- Power Supply simulated status
- DC Load simulated status
- Simulation Mode indicator
- Fault indicator and fault message
- Status/message field

Never set the existing DAQ/Power Supply/DC Load Connected indicators to TRUE merely because simulation is running. Make the simulation state explicit.

---

## 10. CSV Data Logging

Implement a working Save feature using LabVIEW 2019-supported File I/O functions.

Suggested CSV columns:

- Timestamp
- ElapsedTime_s
- State
- Mode
- SOC_percent
- Voltage_V
- Current_A
- Temperature_C
- CycleCount
- SimPowerSupplyEnable
- SimLoadEnable
- Fault
- FaultMessage

Requirements:

1. Choose a file path with a Save File Dialog, or use an existing configured path with a clear UI indication.
2. Write a header row once.
3. Write numeric values using consistent decimal formatting and units in headers.
4. Handle file-open, permission, path, and write errors.
5. Do not silently overwrite an existing user file.
6. Show `Saved successfully` or a meaningful error in the status field.
7. Save while idle and after a test run.
8. If logging data continuously during a run, make file open/write/close behaviour safe and deterministic. If saving a stored history on demand, bound the history and document the limit.
9. Close references on normal Close and on error paths.

---

## 11. Suggested VI/Module Breakdown

Prefer a small number of understandable VIs. Do not create a huge number of tiny VIs or add an architecture framework without need.

Possible structure:

```text
Battery_Test_System_Simulation.lvproj
│
├── Main
│   └── Battery_Test_System_Simulation.vi
│
├── Typedefs
│   ├── Test_State_Enum.ctl
│   ├── Operation_Mode.ctl
│   ├── Simulation_Data.ctl
│   ├── Simulation_Config.ctl
│   └── Log_Record.ctl
│
├── Simulation
│   ├── Initialize_Simulation.vi
│   ├── Update_Charge_Simulation.vi
│   ├── Update_Discharge_Simulation.vi
│   └── Evaluate_Simulation_Safety.vi
│
├── Logging
│   └── Save_Simulation_Log.vi
│
├── Tests
│   └── Simulation_Test.vi or documented test steps
│
└── Documentation
    ├── README.md
    └── BUILD_AND_TEST_REPORT.md
```

This is a proposal, not a requirement to generate every listed file. Reuse existing VIs such as `Stress_Calc_SubVI.vi` only after inspecting their connector panes, documentation, implementation, and relevance.

The MCP repository documents limitations around calls to project-local subVIs during AIXML generation. Build leaf/dependency VIs first, load them correctly when needed, and verify every caller. If the generator cannot handle a local subVI call, do not fake the call or leave a broken VI; choose a verified alternative and explain it.

---

## 12. How to Use LabVIEW MCP Effectively

Use the current MCP tool list and MCP resources. Read the MCP documentation before relying on any specific behaviour.

### Read and inspect first

Use the available read-only tools where exposed:

- `lvai_status` / `pylv_status`: server health, backend, installed/running LabVIEW, and composer status.
- `lvai_list_labview_installations`: discover exact installed versions.
- `lvai_describe_project`: inspect project targets, VIs, dependencies, and missing files.
- `lvai_describe_vi`: inspect each relevant VI, its Front Panel controls/indicators, subVIs, block diagram image and metadata.
- `lvai_convert_vi_to_aixml`: export an existing VI's diagram into textual AIXML for structural inspection.
- `lvai_describe_ctl`: inspect typedefs if the installed server supports that file type. If a `.ctl` cannot be read through `describe_vi`, use the specifically documented typedef reader or local file inspection route.
- `lvai_palette_index`: discover exact installed LabVIEW functions and terminal names.
- `lvai_example_index`: search installed NI examples for state-machine, event-driven UI, charting, and file-logging examples.
- `lvai_aixml_reference`: retrieve the AIXML syntax and verified terminal-name rules.
- `lvai_vi_server_reference`: inspect exact VI Server properties/methods before using Property/Invoke Nodes.
- `lvai_error_list`, `lvai_exec_state`, `lvai_vis_in_memory`, and `lvai_labview_state` if available to investigate broken VIs, unsaved state, and IDE conditions.

Do not assume the exact tool name or schema from this prompt if the installed MCP server differs. Discover the current tools and call only their advertised schemas.

### AIXML workflow

If the MCP route uses AIXML:

1. Read `lvai_aixml_reference` first.
2. Export a similar working VI with `lvai_convert_vi_to_aixml` and study its exact node and terminal names.
3. Search NI examples and installed palettes before authoring a primitive node from scratch.
4. Author AIXML using exact terminal labels and correct UIDs/parents.
5. Run `lvai_check_aixml` as a pre-flight check.
6. Run `lvai_validate_aixml`.
7. Generate to a **new scratch path** with the appropriate generation/conversion tool.
8. Inspect the generated diagram image (`--diagram`, `lvai_render_diagrams`, or the available equivalent).
9. Open the result in LabVIEW 2019 and inspect the actual Front Panel and Block Diagram.
10. Run `lvai_exec_state` / `lvai_error_list` and then execute a safe test VI.
11. Re-export/inspect the saved VI and verify the intended diagram and controls actually exist.

AIXML has no reliable layout coordinates. LabVIEW may choose a diagram layout automatically. Render and inspect it; use the documented layout tool only on a working copy.

### Editing the existing Front Panel

The preferred goal is to preserve the supplied UI. If supported by the installed MCP version and the VI is compatible:

- Use the documented supplied-panel graft workflow (`lvai_graft_diagram`) on a **copy** of the supplied VI.
- Confirm that all scaffold controls have matching types and labels in the supplied Front Panel.
- Use `replaceDiagram` only on the duplicate, after confirming that replacing the duplicate's old diagram is intended.
- Verify that the original Front Panel controls, positions, labels, data types, and typedef bindings survive the graft.
- Use `allowNewControls` only for explicitly requested new indicators/controls and inspect their appearance afterwards.
- Compare the Front Panel before/after using screenshots or rendered panel images.

Do not use `lvai_apply_aixml_to_vi` as an assumed existing-VI patch mechanism. The repository's current safety guide says that route is refused/unusable by default. Do not call it unless the user specifically asks for that exact operation and the current repository docs confirm a working method.

### Layout and rendering

- Render the Front Panel and Block Diagram after important edits.
- Use `lvai_layout_diagram` only on the copied VI and verify its backup, dry-run plan, and rendered result.
- Check that structures, case labels, wire routes, comments, and terminals are visible and not clipped.
- A clean diagram is important, but correctness is more important than visual decoration.

### Running and validation

- `lvai_exec_state` or equivalent static execution checks are necessary but not sufficient.
- `lvai_run_vi_and_read_values` or the available run tool may be used only on a verified simulation-only VI and only after the user has approved execution.
- The MCP repo notes limitations for some non-string indicator readbacks. Judge the run using the VI's own visible outputs, logs, and test assertions, not only a generic tool result.
- A running UI loop must have a reliable Stop/Close path. Never start a top-level infinite UI loop without a planned stop action.

### MCP tool safety

The current MCP project marks many tools as destructive. In particular, VI generation can create/overwrite `.vi` files, VI run tools execute code, and layout tools may save changes in place. Use new paths and backups. Keep mutation confirmations enabled.

---

## 13. Implementation Phases

Work in short phases. At the end of each phase, report what was changed, what was tested, and any blockers.

### Phase 0: Compatibility and project backup

- Run the LabVIEW 2019 MCP compatibility probe.
- Make a working copy of the existing project.
- Inspect all relevant VIs, typedefs, controls, and target ownership.
- Record the initial broken/run state of each relevant VI.
- Do not modify original files.

### Phase 1: Requirements and UI inventory

- Create a control/indicator inventory from the actual `user_interface.vi`.
- Record each control's exact label, data type, terminal/reference identity, mechanical action, default value, and tab/page location.
- Identify the exact Charge and Discharge inputs.
- Identify whether existing graphs are Waveform Charts, Waveform Graphs, or XY Graphs.
- Identify how `main battery tester vi22.vi` and `Stress_Calc_SubVI.vi` relate to the UI.
- Produce a brief architecture plan before creating code.

### Phase 2: Working simulation VI skeleton

- Create a simulation VI under My Computer if appropriate.
- Preserve the existing Front Panel through the documented graft/copy workflow when viable.
- Create/reuse the state typedef and any small configuration/data typedefs.
- Build one main While Loop with Event Structure, state shift register, Case Structure, simulation-data shift register, and Stop/Close logic.
- Implement INIT and IDLE first.
- Open and run the skeleton in LabVIEW 2019.

### Phase 3: Event handling and state machine

Implement and test:

- Start
- Mode selection
- Stop
- Reset Fault
- Save
- Close
- Timeout
- All state cases and Default fallback

Ensure every structure tunnel is wired correctly and error handling is explicit.

### Phase 4: Simulation engine

Implement:

- Initial demo values
- Time-step calculation
- SOC progression
- Simulated voltage/current response
- Simulated temperature response
- Elapsed time
- Cycle completion/count logic
- Output interlock
- Configurable simulation limits and fault injection

No physical I/O calls are allowed in this phase.

### Phase 5: Front Panel refinement

Improve the existing UI while preserving the current controls and meanings. Add SOC, elapsed time, state/status, simulation indicator, and Reset Fault if needed. Verify event behaviour after all UI changes.

### Phase 6: Graphing and CSV logging

- Update the three existing charts.
- Keep bounded graph history.
- Implement CSV Save.
- Test file path selection, headings, sample rows, error handling, and clean file closure.

### Phase 7: Full simulation verification

Perform the test cases listed below in LabVIEW 2019. Fix errors and repeat until all pass.

### Phase 8: Final handoff

Deliver:

- Working `.lvproj` copy.
- Working simulation `.vi`.
- All required `.ctl` typedefs and supporting VIs.
- Screenshots of the Front Panel and Block Diagram.
- MCP compatibility probe and test evidence.
- `README.md` with how to open/run the application.
- `BUILD_AND_TEST_REPORT.md` with pass/fail results and known limitations.
- A clear statement that no physical battery or I/O was tested.

---

## 14. Verification and Acceptance Tests

Run these tests on the actual LabVIEW 2019 installation.

| Test | Action | Expected result |
|---|---|---|
| Open project | Open the copied `.lvproj` | Opens without missing files |
| Open VI | Open simulation VI | Front Panel and Block Diagram load |
| Broken arrow | Inspect Run arrow | VI is not broken |
| Initial state | Run VI | INIT executes then IDLE appears |
| Idle outputs | Leave application idle | Simulated supply/load enables are FALSE |
| Charge start | Select Charge, enter valid demo values, press Start | State becomes CHARGING; simulated supply ON; load OFF |
| Charge progression | Let simulation run | SOC increases within 0–100; charts update |
| Charge completion | Set a short test duration or test completion setting | State moves to STOPPED; both outputs OFF |
| Discharge start | Select Discharge, enter valid values, press Start | State becomes DISCHARGING; supply OFF; load ON |
| Discharge progression | Let simulation run | SOC decreases within 0–100; charts update |
| Discharge completion | Set a short test duration or test completion setting | State moves to STOPPED; both outputs OFF |
| Manual stop | Stop during active simulation | Operation stops immediately; both outputs OFF |
| Interlock | Inspect all states and mode transitions | Supply and load enables are never both TRUE |
| Invalid input | Enter zero/negative/out-of-range values | Start is rejected with a useful message; outputs stay OFF |
| Fault injection | Trigger each simulated fault condition | State becomes FAULT; outputs OFF; reason displayed |
| Fault latch | Try to Start without reset | Start remains blocked |
| Fault reset | Clear injected fault and press Reset Fault | Returns to IDLE safely |
| Cycle count | Complete a full charge/discharge pair | Cycle count increments exactly once |
| Save CSV | Press Save | File is created with headers and correct data rows |
| CSV failure | Use invalid/unwritable path | Helpful error shown; VI remains stable |
| Close | Press Close | Outputs OFF, files closed, loop exits cleanly |
| Repeat run | Start, stop, and restart multiple times | No stale events, latched buttons, or broken state |

Also inspect:

- No coercion dots caused by mismatched typedefs on critical state/mode wires.
- No unwired tunnels.
- No hidden infinite loop or uncontrolled parallel loop.
- No unhandled error clusters on important File I/O or subVI paths.
- No physical I/O node is in the simulation execution path.
- Charts show readable time axes and units.
- The UI clearly says Simulation Mode.

---

## 15. Engineering and Code Quality Rules

- Use English for every file, VI label, control label, comment, and documentation item.
- Use descriptive names such as `Simulation_Data`, `Current_State`, `Next_State`, `SOC_Percent`, `Elapsed_Time_s`, and `Sim_PowerSupply_Enable`.
- Use consistent units in labels and wire names.
- Avoid magic numbers. Put simulation rates and demo limits in a configuration typedef or clearly labelled constants.
- Use error clusters and handle errors in a predictable order where appropriate.
- Keep data flow readable from left to right.
- Keep state-machine logic separate from UI event decoding and simulation calculations.
- Keep physical hardware I/O behind a separate abstraction boundary, but do not implement or activate it yet.
- Do not use local variables as a substitute for clean dataflow unless there is a justified UI-specific need.
- Do not create duplicate controls, enums, or indicators with almost identical names.
- Do not leave random-number demo VIs driving charts as the final simulation logic. Use a deterministic base model.
- Make the simulation repeatable and easy to test.
- Document any assumptions, simplified models, and missing hardware parameters.

---

## 16. Communication Rules for the Coding Agent

Work autonomously where the repository and supplied information are sufficient. Do not repeatedly ask the user to restate facts already provided here.

Ask the user only when a decision is genuinely blocking or when an irreversible action, version change, or overwrite is required.

At each phase boundary, provide a short progress report containing:

1. Files inspected or created.
2. MCP backend and LabVIEW version actually used.
3. What functionality is complete.
4. Whether the VI opened and ran in LabVIEW 2019.
5. Tests passed/failed.
6. Any remaining blocker or assumption.

If something cannot be achieved with the available MCP backend, say exactly what failed. Do not fabricate tool results, screenshots, VI outputs, test results, or hardware status.

**Do not stop after drawing a block diagram. Deliver the actual working `.vi` and prove it runs in LabVIEW 2019.**

---

## 17. First Message / First Actions

Start by doing the following, in order:

1. Confirm the project directory and LabVIEW 2019 installation.
2. Read the current LabVIEW MCP README, safety guide, tool catalogue, AIXML workflow, and backend documentation.
3. Discover the available MCP tools and active backend.
4. Run the disposable LabVIEW 2019 compatibility probe.
5. Report whether the MCP route is verified on LabVIEW 2019 before modifying any project file.
6. If compatibility passes, back up the project and begin Phase 1.
7. If compatibility fails, stop and explain the exact failure and safe alternatives. Do not upgrade LabVIEW or modify the original project without permission.

**Primary goal:** A polished, fully functioning Battery Test System simulation VI, based on the existing Front Panel, created and verified in LabVIEW 2019, with a clean path for future cRIO hardware integration.
