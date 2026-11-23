# Battery Test System Simulation: LabVIEW 2019 Build Guide

You build this by hand in **LabVIEW 2019**. The MCP cannot produce files that LabVIEW 2019 can open.
After each **CHECKPOINT**, save, then tell Claude something like "Part 2 done".
Claude then reads the saved files directly to check them, and later runs the VI in LabVIEW 2019 through ActiveX.

Everything happens in `Build\Simulation\`, the working copy. The original project in the parent folder is not touched.

Conventions used below:
- Palette paths are relative to **Functions > Programming**, e.g. *Comparison > Greater Than 0?*. Quick Drop (Ctrl+Space) is usually faster: type the name in *italics*.
- "**Unbundle by Name: A, B**" means: drop Unbundle by Name, wire the cluster in, grow it to show items A and B.
- "**Bundle by Name: A ← x**" means: wire the cluster to the middle `input cluster` terminal, show item A, wire x to it.
- Labels include units. Type them exactly, because subVI and cluster names are referenced later.
- `degC` is used instead of the degree sign to keep files and CSV plain ASCII.

---

## Part 0: Open the working project

1. Close the original `BATTERY TEST SYSTEM FINAL.lvproj` (save nothing in it).
2. Open `Build\Simulation\Battery_Test_System_Simulation.lvproj`.
3. Right-click **My Computer > Add > File...** and add `Battery_Test_System_Simulation.vi`.
   Claude already created this file: it is a copy of `user_interface.vi`, so its panel is identical to yours.
4. Right-click **My Computer > Add > Folder (Virtual)** three times to create `Typedefs`, `SubVIs` and `Main`. Drag the VI into `Main`.

Leave the cRIO target and the VIs under it alone.

---

## Part 1: Typedefs (4 new files, 1 reused)

For each typedef: **File > New... > Other Files > Custom Control**, build it, then use the Control Editor toolbar to set **Control Type → Type Def.** and save it to `Build\Simulation\` under the given name. Add each one to the `Typedefs` folder.

### 1.1 `Sim_State_Enum.ctl` (Enum, U16)
Items in exactly this order:
```
INIT
IDLE
CHARGING
DISCHARGING
STOPPED
FAULT
```
(The existing `Test_State_Enum.ctl` holds 8 different items, `CHARGE _CC`, `REST`, ... and is used by the cRIO VI, so it is left unchanged.)

### 1.2 Operation mode: reuse `Test_State_Enum2.ctl`
It is already a typedef enum `Charge, Discharge`. Use it as-is wherever this guide says **Mode typedef**.

### 1.3 `Sim_Data.ctl` (Cluster)
Put controls into the cluster in this order. All numerics are DBL unless stated otherwise; the default value is 0, FALSE or empty.

| # | Label | Type |
|---|---|---|
| 1 | `SOC (%)` | DBL |
| 2 | `Voltage (V)` | DBL |
| 3 | `Current (A)` | DBL |
| 4 | `Temperature (degC)` | DBL |
| 5 | `Run Time (s)` | DBL |
| 6 | `Elapsed (s)` | DBL |
| 7 | `Cycle Count` | U32 |
| 8 | `Active Mode` | **Mode typedef** (drop it with *Select a Control...* → `Test_State_Enum2.ctl`) |
| 9 | `Setpoint Voltage (V)` | DBL |
| 10 | `Setpoint Current (A)` | DBL |
| 11 | `Setpoint C-Rate (1/h)` | DBL |
| 12 | `Setpoint Duration (min)` | DBL |
| 13 | `Sim PS Enable` | Boolean |
| 14 | `Sim Load Enable` | Boolean |
| 15 | `Charge Half Done` | Boolean |
| 16 | `Discharge Half Done` | Boolean |
| 17 | `Fault` | Boolean |
| 18 | `Fault Code` | I32 |
| 19 | `Fault Message` | String |
| 20 | `Fault Time` | String |
| 21 | `Status Message` | String |

### 1.4 `Sim_Settings.ctl` (Cluster): DEMO values only, not battery limits
Don't set default values here. Part 3 sets them on the main VI's instance of this cluster.

| # | Label | Type | Demo default (set in Part 3) |
|---|---|---|---|
| 1 | `UI Update Interval (ms)` | I32 | 200 |
| 2 | `Max dt (s)` | DBL | 1 |
| 3 | `Initial SOC (%)` | DBL | 50 |
| 4 | `Rest Voltage (V)` | DBL | 12 |
| 5 | `Ambient Temperature (degC)` | DBL | 25 |
| 6 | `Voltage Time Constant (s)` | DBL | 5 |
| 7 | `Current Time Constant (s)` | DBL | 1 |
| 8 | `Thermal Time Constant (s)` | DBL | 120 |
| 9 | `Heating Coefficient (degC/s per A^2)` | DBL | 0.002 |
| 10 | `SOC Speed Factor` | DBL | 1 |
| 11 | `Charge Complete SOC (%)` | DBL | 100 |
| 12 | `Discharge Complete SOC (%)` | DBL | 0 |
| 13 | `Max Voltage Limit (V)` | DBL | 15 |
| 14 | `Max Current Limit (A)` | DBL | 10 |
| 15 | `Max Temperature Limit (degC)` | DBL | 45 |
| 16 | `Max C-Rate (1/h)` | DBL | 5 |
| 17 | `Max Duration (min)` | DBL | 600 |
| 18 | `History Length (samples)` | I32 | 3000 |
| 19 | `Inject E-Stop` | Boolean (switch) | FALSE |
| 20 | `Inject Overvoltage` | Boolean (switch) | FALSE |
| 21 | `Inject Overcurrent` | Boolean (switch) | FALSE |
| 22 | `Inject Overtemperature` | Boolean (switch) | FALSE |

### 1.5 `Sim_Log_Record.ctl` (Cluster)
| # | Label | Type |
|---|---|---|
| 1 | `Timestamp` | String |
| 2 | `State` | `Sim_State_Enum.ctl` |
| 3 | `Data` | `Sim_Data.ctl` |

**CHECKPOINT 1:** save all, then tell Claude "Part 1 done". Claude checks every `.ctl`: that it is a typedef, its item names and its field order.

---

## Part 2: SubVIs (5 VIs, no front panel styling needed)

Create each one with **File > New VI**, save it to `Build\Simulation\` and add it to `SubVIs`.
Use the **4-2-2-4** connector pane. Inputs go on the left and outputs on the right. Make the first cluster input "Required".
After each one, check that its Run arrow is not broken.

### 2.1 `Sim_Validate_Setpoints.vi`
> **DONE (generated by Claude, 2026-11-23). Tested 9/9 in LabVIEW 2019.** You only need to add it to the `SubVIs` folder in the project. Instead of Pick Line, it uses Index Array on a constant array of messages. The behaviour below is unchanged.

**Panel:** controls `Voltage (V)`, `Current (A)`, `C-Rate (1/h)`, `Duration (min)` (all DBL), `Settings` (Sim_Settings typedef). Indicators: `Valid?` (Boolean), `Message` (String).

**Diagram:**
1. Build Array of `Voltage`, `Current`, `C-Rate`, `Duration` (in that order) → **values**.
2. Unbundle by Name on Settings: `Max Voltage Limit (V)`, `Max Current Limit (A)`, `Max C-Rate (1/h)`, `Max Duration (min)` → Build Array in the same order → **limits**.
3. *Greater Than 0?* (values) → A. *Less Or Equal?* (x = values, y = limits) → B. *And* (A, B) → **ok[]**. Comparison works element by element. NaN and ±Inf fail automatically.
4. *Search 1D Array* (array = ok[], element = FALSE constant) → **idx**.
5. *Less Than 0?* (idx) → `Valid?`.
6. *Pick Line* (string = empty, multi-line string = constant below, line index = idx) → picked.
   String constant, one line each:
   ```
   Rejected: Voltage setpoint must be > 0 and <= Max Voltage Limit (Simulation Settings).
   Rejected: Current setpoint must be > 0 and <= Max Current Limit (Simulation Settings).
   Rejected: C-Rate must be > 0 and <= Max C-Rate (Simulation Settings).
   Rejected: Duration must be > 0 and <= Max Duration (Simulation Settings).
   ```
7. *Select* (s = Valid?, t = `"Setpoints OK."`, f = picked) → `Message`.

Connector pane: left Voltage, Current, C-Rate, Duration, Settings. Right Valid?, Message.

> **2.2 – 2.5: DONE (generated by Claude, 2026-11-23). 31/31 tests pass in LabVIEW 2019.** Add all four to `SubVIs` in the project. The sections below describe what each VI does. The generated diagrams use Select nodes instead of Case Structures, and Concatenate Strings instead of a multi-input Format Into String, with the same behaviour. `Sim_Save_CSV.vi` has one extra input, `File Path (empty = dialog)`. Leave it unwired in the main VI to get the file dialog.

### 2.2 `Sim_Update_Model.vi`: the replaceable "sensor source"
**Panel:** controls `Sim Data in` (Sim_Data), `Settings` (Sim_Settings), `State` (Sim_State_Enum), `dt (s)` (DBL). Indicator: `Sim Data out` (Sim_Data).

**Diagram:**
1. Unbundle by Name on Sim Data in: `SOC (%)`, `Voltage (V)`, `Current (A)`, `Temperature (degC)`, `Run Time (s)`, `Elapsed (s)`, `Setpoint Voltage (V)`, `Setpoint Current (A)`, `Setpoint C-Rate (1/h)`.
2. Unbundle by Name on Settings: `Voltage Time Constant (s)`, `Current Time Constant (s)`, `Thermal Time Constant (s)`, `Ambient Temperature (degC)`, `Heating Coefficient (degC/s per A^2)`, `Rest Voltage (V)`, `SOC Speed Factor`.
3. State → *To Double Precision Float* → `st`.
4. Drop a **Formula Node** (*Structures > Formula Node*). Right-click its border and use **Add Input** for each name, then wire:

   | Input | Wire from |
   |---|---|
   | `st` | State (as DBL) |
   | `soc` `v` `i` `t` | SOC, Voltage, Current, Temperature |
   | `rt` `el` | Run Time, Elapsed |
   | `vset` `iset` `crate` | Setpoint Voltage, Setpoint Current, Setpoint C-Rate |
   | `dt` | dt (s) |
   | `spd` | SOC Speed Factor |
   | `tauV` `tauI` `tauT` | Voltage/Current/Thermal Time Constant |
   | `tamb` `heatK` `vrest` | Ambient Temperature, Heating Coefficient, Rest Voltage |

   **Add Output**: `socO`, `vO`, `iO`, `tO`, `rtO`, `elO`, `psO`, `ldO`.

   Type this code inside the node exactly (state numbers: 2 = CHARGING, 3 = DISCHARGING):
   ```c
   /* DEMONSTRATION MODEL - idealized, not an electrochemical battery model.
      SOC: ideal C-rate integration. V and I: first-order approach to setpoint.
      T: current-squared heating with first-order cooling to ambient. */
   float64 kV, kI, dSoc, vT, iT;
   kV = min(dt / max(tauV, 0.001), 1);
   kI = min(dt / max(tauI, 0.001), 1);
   dSoc = crate * 100 * dt * spd / 3600;
   psO = 0;
   ldO = 0;
   if (st == 2) {
       psO = 1; vT = vset; iT = iset;
   } else if (st == 3) {
       ldO = 1; vT = vset; iT = -iset; dSoc = -dSoc;
   } else {
       vT = vrest; iT = 0; dSoc = 0;
   }
   socO = min(max(soc + dSoc, 0), 100);
   vO = v + (vT - v) * kV;
   if (psO + ldO == 0) iO = 0; else iO = i + (iT - i) * kI;
   tO = t + dt * (heatK * iO * iO - (t - tamb) / max(tauT, 0.001));
   rtO = rt + dt;
   if (psO + ldO > 0) elO = el + dt; else elO = el;
   ```
5. `psO` → *Not Equal To 0?* → PS bool. `ldO` → *Not Equal To 0?* → Load bool.
6. Bundle by Name on Sim Data in: `SOC (%)` ← socO, `Voltage (V)` ← vO, `Current (A)` ← iO, `Temperature (degC)` ← tO, `Run Time (s)` ← rtO, `Elapsed (s)` ← elO, `Sim PS Enable` ← PS bool, `Sim Load Enable` ← Load bool → `Sim Data out`.

Connector pane: left Sim Data in, Settings, State, dt (s). Right Sim Data out.

> **The output interlock lives here.** Only state CHARGING can set PS, and only DISCHARGING can set Load. Every other state forces both OFF. Discharge current is shown as negative.

### 2.3 `Sim_Check_Safety.vi`
**Panel:** controls `Sim Data in`, `Settings`. Indicators `Sim Data out`, `Fault Active?` (Boolean).

**Diagram:**
1. Unbundle by Name on Sim Data in: `Voltage (V)`, `Current (A)`, `Temperature (degC)`, `Sim PS Enable`, `Sim Load Enable`, `Fault`, `Fault Time`.
2. Unbundle by Name on Settings: `Inject E-Stop`, `Inject Overvoltage`, `Inject Overcurrent`, `Inject Overtemperature`, `Max Voltage Limit (V)`, `Max Current Limit (A)`, `Max Temperature Limit (degC)`.
3. Conditions, in priority order:
   - c1 = Inject E-Stop
   - c2 = *Or*(Inject Overvoltage, *Greater?*(Voltage, Max Voltage Limit))
   - c3 = *Or*(Inject Overcurrent, *Greater?*(*Absolute Value*(Current), Max Current Limit))
   - c4 = *Or*(Inject Overtemperature, *Greater?*(Temperature, Max Temperature Limit))
   - c5 = *And*(Sim PS Enable, Sim Load Enable)
4. Build Array c1..c5 (in order) → *Search 1D Array* (element = TRUE) → **idx**. *Greater Or Equal To 0?*(idx) → `Fault Active?`.
5. Case Structure, selector = Fault Active?
   - **False:** wire Sim Data in straight through to the output tunnel.
   - **True:**
     - *Pick Line* (multi-line string below, line index = idx) → reason
       ```
       E-STOP (simulated fault injection)
       OVERVOLTAGE (simulated, above demo Max Voltage Limit)
       OVERCURRENT (simulated, above demo Max Current Limit)
       OVERTEMPERATURE (simulated, above demo Max Temperature Limit)
       OUTPUT INTERLOCK (supply and load both enabled)
       ```
     - *Format Into String*, format `%s (V=%.2f V, I=%.2f A, T=%.1f degC)`, inputs reason, Voltage, Current, Temperature → **msg**.
     - *Format Date/Time String* (time format `%Y-%m-%d %H:%M:%S`) → now. *Select*(s = Fault, t = Fault Time, f = now) → keeps the first fault time.
     - *Concatenate Strings*: `"FAULT latched: "`, msg, `". Remove the cause, then press Reset Fault."` → status.
     - *Increment*(idx) → code.
     - Bundle by Name on Sim Data in: `Fault` ← TRUE, `Fault Code` ← code, `Fault Message` ← msg, `Fault Time` ← selected time, `Sim PS Enable` ← FALSE, `Sim Load Enable` ← FALSE, `Charge Half Done` ← FALSE, `Discharge Half Done` ← FALSE, `Status Message` ← status → output tunnel.
6. Output tunnel → `Sim Data out`.

Connector pane: left Sim Data in, Settings. Right Sim Data out, Fault Active?.

### 2.4 `Sim_Check_Completion.vi`
**Panel:** controls `Sim Data in`, `Settings`, `State` (Sim_State_Enum). Indicators `Sim Data out`, `Done?` (Boolean).

**Diagram:**
1. Unbundle by Name on Sim Data in: `SOC (%)`, `Elapsed (s)`, `Setpoint Duration (min)`, `Cycle Count`, `Charge Half Done`, `Discharge Half Done`.
2. Unbundle by Name on Settings: `Charge Complete SOC (%)`, `Discharge Complete SOC (%)`.
3. isCharging = *Equal?*(State, Sim_State_Enum constant `CHARGING`).
4. socDone = *Select*(isCharging, *Greater Or Equal?*(SOC, Charge Complete SOC), *Less Or Equal?*(SOC, Discharge Complete SOC)).
5. timeDone = *Greater Or Equal?*(Elapsed, *Multiply*(Setpoint Duration, 60)).
6. Done = *Or*(socDone, timeDone) → `Done?`.
7. Case Structure on Done:
   - **False:** pass Sim Data in through.
   - **True:**
     - chgNow = *And*(socDone, isCharging). disNow = *And*(socDone, *Not*(isCharging)).
     - newCHD = *Or*(Charge Half Done, chgNow). newDHD = *Or*(Discharge Half Done, disNow).
     - full = *And*(newCHD, newDHD).
     - cycleOut = *Add*(Cycle Count, *Boolean To (0,1)*(full)). Right-click the Add output if needed: **Representation > U32**.
     - CHD out = *And*(newCHD, *Not*(full)). DHD out = *And*(newDHD, *Not*(full)).
     - Message:
       `m1 = Select(isCharging, "Charge complete (SOC target reached).", "Discharge complete (SOC target reached).")`
       `m2 = Select(socDone, m1, "Stopped: duration elapsed (half-cycle NOT counted).")`
       `msg = Select(full, "Full charge+discharge cycle completed. Cycle Count incremented.", m2)`
     - Bundle by Name: `Cycle Count` ← cycleOut, `Charge Half Done` ← CHD out, `Discharge Half Done` ← DHD out, `Status Message` ← msg.

Connector pane: left Sim Data in, Settings, State. Right Sim Data out, Done?.

> **Cycle definition:** a half-cycle counts only when its SOC completion target is reached. Duration expiry, a manual Stop and a Fault never count, and a Fault also clears both half flags. Cycle Count increases by 1 when both halves are done (in either order), and then both flags clear.

### 2.5 `Sim_Save_CSV.vi`
**Panel:** control `Log Records` (an array of `Sim_Log_Record.ctl`). Indicators `Status Message` (String), `Saved?` (Boolean).

**Diagram:**
1. **For Loop** with Log Records auto-indexed in:
   - Unbundle by Name on the record: `Timestamp`, `State`, `Data`.
   - Unbundle by Name on Data: `Run Time (s)`, `Elapsed (s)`, `Active Mode`, `SOC (%)`, `Voltage (V)`, `Current (A)`, `Temperature (degC)`, `Cycle Count`, `Sim PS Enable`, `Sim Load Enable`, `Fault`, `Fault Message`.
   - *Boolean To (0,1)* on each of the 3 booleans.
   - *Format Into String*. Grow it to 14 inputs, wired in this order: Timestamp, Run Time, Elapsed, State, Active Mode, SOC, Voltage, Current, Temperature, Cycle Count, PS(0/1), Load(0/1), Fault(0/1), Fault Message. Format string:
     ```
     %s,%.3f,%.3f,%s,%s,%.2f,%.4f,%.4f,%.2f,%d,%d,%d,%d,"%s"
     ```
     (Enums formatted with `%s` print their item name.)
   - *Concatenate Strings*(formatted, **End of Line** constant) → auto-indexed output tunnel.
2. *Concatenate Strings* with three inputs: header constant, End of Line, and the line array from the loop (an array input concatenates all its elements) → **text**. Header constant:
   ```
   Timestamp,RunTime_s,ElapsedTime_s,State,Mode,SOC_percent,Voltage_V,Current_A,Temperature_C,CycleCount,SimPowerSupplyEnable,SimLoadEnable,Fault,FaultMessage
   ```
3. *Open/Create/Replace File*: prompt `"Save simulation log (.csv)"`, operation = **replace or create with confirmation**, access = **write-only**. Leave the path unwired so a file dialog opens, and the confirmation prevents silent overwrite.
4. → *Write to Text File* (text) → *Refnum to Path* (*File I/O > Advanced File Functions*) → path → *Close File*. Close File runs even after an error, so the reference is always closed.
5. *Unbundle by Name* on Close File's error out: `code`, `source`. Case Structure on `code`:
   - `0`: *Format Into String* `Saved successfully: %s (%d samples)` with *Path To String*(path) and *Array Size*(Log Records). Saved? = TRUE.
   - `43`: `"Save cancelled."` Saved? = FALSE.
   - `Default`: *Format Into String* `Save FAILED (error %d): %s` with code and source. Saved? = FALSE.
6. Wire the error after the case into *Clear Errors.vi* (*Dialog & User Interface*). The error has now been reported in Status Message, so no automatic error dialog appears.

Connector pane: left Log Records. Right Status Message, Saved?.

**CHECKPOINT 2:** all five subVIs saved and not broken. Tell Claude "Part 2 done". Claude reads each diagram from the file and runs the pure ones (2.1 to 2.4) with test inputs through ActiveX.

---

## Part 3: Front panel of `Battery_Test_System_Simulation.vi` (keep the layout, improve it)

**First delete the old diagram code.** Open the block diagram, press Ctrl+A, then Delete, then **Ctrl+B** (remove broken wires).
LabVIEW does not delete front-panel terminals this way. They stay on the diagram, so your panel controls are kept.
Check that the Front Panel still has every control. If anything disappeared, Ctrl+Z and tell Claude.

### 3.1 Rename and re-type existing objects (in the copy only)
| Existing label | Change |
|---|---|
| `Charging Voltage` | Label → `Charge Voltage (V)` |
| `Charge Current` | → `Charge Current (A)` |
| `C-Rate` | → `Charge C-Rate (1/h)` |
| `Charge Duration` | → `Charge Duration (min)` |
| `DisCharging Voltage 2` | → `Discharge Voltage (V)` |
| `Charge Current 2` | → `Discharge Current (A)` |
| `C-Rate 2` | → `Discharge C-Rate (1/h)` |
| `Charge Duration 2` | → `Discharge Duration (min)` |
| `DC Voltage` (numeric) | → `DC Voltage (V)` |
| `DC Current` (numeric) | → `DC Current (A)` |
| `Temperature` (numeric) | → `Temperature (degC)` |
| `DC Voltage` (chart, U64) | Right-click → **Replace** → **XY Graph** (same style family if your palette has one). Label `DC Voltage Graph`, X axis name `Time (s)`, Y axis name `Voltage (V)` |
| `DC Current` (chart, U64) | Same → `DC Current Graph`, axes `Time (s)` / `Current (A)` |
| `Temperature` (graph) | Same → `Temperature Graph`, axes `Time (s)` / `Temperature (degC)` |
| `Cycle` (slide) | **Replace → Numeric Indicator**, label `Cycle Count`, Representation **U32** |
| `Clock` (blank string beside Close) | Label → `Status Message`. Make it wider and taller and set it to show multiple lines. This is the message field |
| `Select Function` (radio buttons) | Rename the two **button labels** inside it (not the captions): `Button 1` → `Charge`, `Button 2` → `Discharge` |
| `Start Button`, `Stop Button`, `Save Button`, `Close Button` | Check that **Mechanical Action = Latch When Released** |
| `DAQ CONNECTED?`, `Power Supply Connected?`, `DC Load Connected?` | Keep them. Add a free label next to them: `Hardware: NOT CONNECTED (simulation)` |

Give every DBL setpoint control **Data Entry** limits of minimum 0 (Response: Ignore). The real validation happens in code, so this is only a convenience.

### 3.2 Add new objects
| New object | Type / where |
|---|---|
| Free label `SIMULATION MODE - simulated data, no hardware connected` | Top strip, large bold yellow or orange text on the black background |
| `Current State` | Indicator from `Sim_State_Enum.ctl` (*Select a Control...*), top strip |
| `SOC (%)` | Numeric indicator DBL, 1 decimal, top strip |
| `SOC Bar` | *Numeric > Progress Bar* (or Horizontal Fill Slide as an indicator), scale 0 to 100, next to SOC |
| `Elapsed Time (s)` | Numeric indicator DBL, top strip |
| `Sim Power Supply Output` | Round LED, green when ON |
| `Sim DC Load Output` | Round LED, green when ON |
| `Fault` | Round LED, red when ON |
| `Fault Message` | String indicator, near Status Message |
| `Reset Fault` | Button (OK-button style), **Latch When Released**, in the left column below Start |
| `Simulation Settings (DEMO ONLY)` | Control from `Sim_Settings.ctl`. Place it below the tab control, or extend the panel downward. Arrange the items in two columns |

Then enter the demo defaults from the table in 1.4 into `Simulation Settings (DEMO ONLY)`. Suggested setpoints:
- Charge tab: 14.0 V, 5 A, 1 /h, 10 min.
- Discharge tab: 11.0 V, 5 A, 1 /h, 10 min.

Then **Edit > Make Current Values Default**.

Suggested layout: SIMULATION MODE banner, state, SOC, elapsed, cycle and hardware LEDs across the top. Start, Reset Fault and Select Function on the left. Tabs in the centre. Three graphs on the right. Status Message, Fault and Fault Message at the bottom.

**CHECKPOINT 3:** save, then tell Claude "Part 3 done". Claude checks the panel inventory from the file.

---

## Part 4: Block diagram of the main VI

### 4.1 Before the loop (left side)
- `Sim_State_Enum` constant set to `INIT` → state shift register (SR).
- `Sim_Data` typedef constant → data SR.
- *Tick Count (ms)* → tick SR.
- Empty array constant containing a `Sim_Log_Record` typedef constant → log SR.
- FALSE constant → `DAQ CONNECTED?`, `Power Supply Connected?` and `DC Load Connected?` terminals. These are written once and never set TRUE in simulation.

### 4.2 While Loop: 4 shift registers (State, Sim Data, Last Tick, Log)
Inside the loop, from left to right:

**A. Settings and mode**
- `Simulation Settings (DEMO ONLY)` terminal (inside the loop, so it is read live) → Unbundle by Name: `UI Update Interval (ms)`, `Max dt (s)`, `History Length (samples)`.
- `Select Function` terminal → Case Structure **Mode Map**:
  - `"Charge", Default` frame: Mode typedef constant `Charge` → tunnel **Mode**.
  - `"Discharge"` frame: Mode constant `Discharge`.
  - This value is read when the iteration starts. That is correct for Start, because changing Select Function triggers its own event iteration first. The Select Function event itself must use its **NewVal** instead (see below).

**B. Measured time step** (no 200 ms assumption)
- *Tick Count (ms)* → now. *Subtract*(now, Last Tick SR) → *To Double* → *Divide* by 1000 → *In Range and Coerce* (upper = Max dt, lower = 0) → **dt** from the `coerced(x)` output.
- now → right tick SR.
- Clamping to Max dt means a dialog or stall cannot cause an SOC jump.

**C. Event Structure.** Timeout = `UI Update Interval (ms)`.
Wire in: State SR, Sim Data SR, Mode, Settings, Log SR.
Output tunnels: **Requested State**, **Sim Data**, **Stop Loop?**. Right-click Stop Loop? → **Use Default If Unwired** (FALSE). Wire **every** State and Sim Data output in every case.

| Event case | Contents |
|---|---|
| **Timeout** | State → Requested State. Sim Data passes through. |
| **"Start Button": Value Change** | Put the **Start Button terminal** in here (this resets the latch). Case Structure on State: |
| | • `"CHARGING", "DISCHARGING"`: Bundle Status Message ← `"Already running - press Stop first."`. State passes through. |
| | • `"FAULT"`: Status ← `"Start blocked: fault latched. Remove the cause and press Reset Fault."`. State passes through. |
| | • `"INIT", "IDLE", "STOPPED"`: Case on **Mode**. `Charge` frame: **Charge** setpoint terminals (`Charge Voltage (V)`, `Charge Current (A)`, `Charge C-Rate (1/h)`, `Charge Duration (min)`) → 4 tunnels, constant `CHARGING` → tunnel. `Discharge` frame: the four **Discharge** terminals and `DISCHARGING`. Then `Sim_Validate_Setpoints.vi`(V, I, C, D, Settings). Then a Case on **Valid?**: True → Bundle by Name `Active Mode` ← Mode, `Setpoint Voltage (V)` ← V, `Setpoint Current (A)` ← I, `Setpoint C-Rate (1/h)` ← C, `Setpoint Duration (min)` ← D, `Elapsed (s)` ← 0, `Status Message` ← *Format Into String*(`"%s started (SIMULATED)."`, Mode). Requested ← CHARGING/DISCHARGING. False → Status ← Message, State passes through. |
| **"Stop Button": Value Change** | Stop Button terminal inside. Case on State: `"CHARGING", "DISCHARGING"` → Requested `STOPPED`, Status `"Stopped by operator - outputs OFF (half-cycle not counted)."`. `Default` → State passes through, Status `"Nothing running."` |
| **"Select Function": Value Change** | Use the event data node's **NewVal**. Case on State: `"CHARGING", "DISCHARGING"` → Status `"Mode change ignored while running - press Stop first."`. `Default` → inner Case on NewVal: `"Charge"` → Tab Control constant `Charge` (right-click the Tab Control terminal → Create Constant), `"Discharge"` → `Discharge` → **Local Variable** of Tab Control. Status ← *Format Into String*(`"Mode selected: %s"`, NewVal). State passes through in both. |
| **"Save Button": Value Change** | Save Button terminal inside. `Sim_Save_CSV.vi`(Log) → Bundle Status Message ← its Status Message. State passes through. |
| **"Reset Fault": Value Change** | Reset Fault terminal inside. Case on State: `"FAULT"` → Bundle `Fault` ← F, `Fault Code` ← 0, `Fault Message` ← "", `Fault Time` ← "", `Status Message` ← `"Fault reset requested - returning to IDLE."`, Requested `IDLE`. `Default` → Status `"No latched fault to reset."`, State passes through. If the cause is still present, the safety check later in the same iteration latches FAULT again. |
| **"Close Button": Value Change** | Close Button terminal inside. Requested `STOPPED` (so the model forces outputs OFF on the last iteration). Status `"Closing - outputs OFF."`. **Stop Loop?** ← TRUE. |
| *(optional)* **Panel Close?** | Discard? ← TRUE, Requested `STOPPED`, Stop Loop? ← TRUE. Closing the window X then shuts down cleanly. |

**D. State Case Structure** (selector = Requested State). Outputs **Next State** and **Sim Data**.

| Frame | Contents |
|---|---|
| `"INIT"` | Bundle by Name on a fresh `Sim_Data` constant: `SOC (%)` ← Settings.Initial SOC, `Voltage (V)` ← Settings.Rest Voltage, `Temperature (degC)` ← Settings.Ambient Temperature, `Status Message` ← `"Initialized. SIMULATION MODE - no hardware connected."`. Next ← `IDLE`. |
| `"IDLE", "STOPPED", "FAULT"` | Pass Sim Data through. Next ← Requested State. |
| `"CHARGING", "DISCHARGING"` | `Sim_Check_Completion.vi`(Sim Data, Settings, Requested State) → Sim Data. *Select*(Done?, `STOPPED`, Requested State) → Next. |
| `Default` | Next ← `FAULT`. Bundle `Fault` ← T, `Fault Code` ← 99, `Fault Message` ← `"Unexpected state (software error)"`, `Status Message` ← same. |

**E. Model, safety and final state**
- `Sim_Update_Model.vi`(Sim Data, Settings, Next State, dt) → Sim Data.
- `Sim_Check_Safety.vi`(Sim Data, Settings) → Sim Data, Fault Active?.
- *Select*(Fault Active?, `FAULT` constant, Next State) → **Final State** → right state SR **and** `Current State` indicator.
- Final Sim Data → right data SR.

**F. Bounded log** (also feeds the graphs and the CSV)
- *Format Date/Time String* (`%Y-%m-%d %H:%M:%S%3u`) → Bundle by Name on a `Sim_Log_Record` constant: `Timestamp`, `State` ← Final State, `Data` ← final Sim Data → record.
- *Build Array* (Log SR on top, record below) → grown. The output must be a **1D** array of records. LabVIEW normally switches to *Concatenate Inputs* by itself when you wire an array plus one element. If the output shows as 2D, right-click and **check** Concatenate Inputs.
- *Array Size*(grown) → *Subtract* History Length → *Max & Min* with 0 → start index (max output). *Array Subset*(grown, index = start, length = History Length) → right Log SR.

**G. Graphs**
- For Loop with the bounded log auto-indexed in: Unbundle by Name `Data` → Unbundle by Name `Run Time (s)`, `Voltage (V)`, `Current (A)`, `Temperature (degC)` → 4 auto-indexed outputs.
- *Bundle*(Run Time[], Voltage[]) → `DC Voltage Graph`. *Bundle*(Run Time[], Current[]) → `DC Current Graph`. *Bundle*(Run Time[], Temperature[]) → `Temperature Graph`.

**H. Indicators.** Unbundle by Name on the final Sim Data:
`SOC (%)` → `SOC (%)` and `SOC Bar`. `Voltage (V)` → `DC Voltage (V)`. `Current (A)` → `DC Current (A)`. `Temperature (degC)` → `Temperature (degC)`. `Elapsed (s)` → `Elapsed Time (s)`. `Cycle Count` → `Cycle Count`. `Sim PS Enable` → `Sim Power Supply Output`. `Sim Load Enable` → `Sim DC Load Output`. `Fault` → `Fault`. `Fault Message` → `Fault Message`. `Status Message` → `Status Message`.

**I. Stop.** Stop Loop? → the loop's conditional terminal (Stop if True).

There is no physical I/O anywhere. Before saving, check: no unwired tunnels (no white-centred tunnels), and no coercion dots on the State and Sim Data wires.

**CHECKPOINT 4:** Run arrow not broken. Save, then tell Claude "Part 4 done". Claude reads the diagram from the file, then runs the VI in LabVIEW 2019 through ActiveX while you click through the test list. Claude polls the indicators and checks the CSV.

---

## Part 5: Acceptance tests (run together with Claude)
| # | Action | Expected |
|---|---|---|
| 1 | Run | `Current State` INIT → IDLE. Both Sim outputs OFF. Hardware LEDs OFF. |
| 2 | Charge, Start (valid values) | CHARGING. Supply ON, Load OFF. SOC rises, V → 14 V, I → 5 A, T rises slowly. Graphs update. |
| 3 | Set `SOC Speed Factor` = 60 and charge | SOC reaches 100 in about 30 s → STOPPED, "Charge complete", both outputs OFF. |
| 4 | Discharge, Start | DISCHARGING. Supply OFF, Load ON. I → -5 A. SOC falls. |
| 5 | Discharge to 0 % | STOPPED. **Cycle Count = 1** (charge done + discharge done). |
| 6 | Start, then Stop | STOPPED immediately. Outputs OFF. Cycle unchanged. |
| 7 | Charge Current = 0 or -1, then Start | Rejected, with a message naming the current. State unchanged. Outputs OFF. |
| 8 | Each `Inject ...` switch | FAULT, both outputs OFF, reason and time shown. |
| 9 | Start while FAULT | Blocked, with a message. |
| 10 | Reset Fault with the injection still ON | Stays FAULT. With it OFF → IDLE. |
| 11 | Charge at 10 A (Max Current Limit 10 A) | T rises toward 49 degC → OVERTEMPERATURE fault at 45 degC (takes a few minutes). |
| 12 | Save → choose a new `.csv` | "Saved successfully ..." and Claude checks the file's header and rows. |
| 13 | Save → `C:\Windows\test.csv` | "Save FAILED (error 8 ...)". VI keeps running. |
| 14 | Save → an existing file → No | "Save cancelled." No overwrite. |
| 15 | Close | Outputs OFF, the loop ends, and the Run arrow returns to idle. |
| 16 | Start/Stop/Start several times | No stuck buttons and no stale state. |

## Assumptions and limits (also for the README)
- All values are **simulated demonstration values**. Nothing here is a lithium-ion safety limit or a validated battery model.
- SOC uses the ideal C-rate model `dSOC = C × 100 × dt / 3600`. `SOC Speed Factor` only speeds up testing.
- The model is a separate subVI on purpose. A later hardware phase replaces `Sim_Update_Model.vi` with cRIO reads and writes without changing the UI or the state machine.
- Save writes the last `History Length` samples (default 3000 ≈ 10 minutes at 200 ms).
