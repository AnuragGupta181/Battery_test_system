# UI Styling Guide: Silver Look for `Battery_Test_System_Main.vi`

This is an optional, purely cosmetic step that you do by hand in **LabVIEW 2019**. It takes about 20–30 minutes.

The VI already works without it. Replacing and moving controls does **not** change the block diagram logic, as long as you follow the checks below.

> Why manual: an automatic layout helper was tried (see `docs/reports/BUILD_MANIFEST.md`). LabVIEW returned invalid control references to it (error 1055), so it was stopped.

---

## Before you start

1. Open `Build\Simulation\Battery_Test_System_Simulation.lvproj`, then `Main\Battery_Test_System_Main.vi`.
2. Make a safety copy: **File ▸ Save As… ▸ Copy ▸ Create unopened disk copy**. Name it `Battery_Test_System_Main_before_UI.vi`. You keep working in the original.
3. Work on the Front Panel (**Ctrl+E** switches between panel and diagram).

**Golden rules**
- Never **delete** a control and drop a new one. Always use **right-click ▸ Replace**, which keeps the wiring and the button events.
- After replacing a button, check its **Mechanical Action**. It must be **Latch When Released**.
- After each group of changes, check that the **Run arrow** (top left) is still solid. If it breaks, press **Ctrl+Z**.
- Don't change control **labels**. The code, the events and the tests use them. Use **captions** if you want different visible text (right-click ▸ Visible Items ▸ Caption).

---

## 1. Replace controls with Silver versions

For each row: right-click the control ▸ **Replace ▸ Silver ▸ …**

| Control(s) | Replace with | After replacing |
|---|---|---|
| `Start`, `Stop`, `Reset Fault`, `Save`, `Close` | **Silver ▸ Boolean ▸ Push Button** (or *Rectangular Button*) | Right-click ▸ **Mechanical Action ▸ Latch When Released**. Optionally show a caption with the button text |
| `Sim Power Supply Output`, `Sim DC Load Output` | **Silver ▸ Boolean ▸ Round LED** | Properties ▸ Appearance: ON = green |
| `Fault` | **Silver ▸ Boolean ▸ Round LED** | Properties ▸ Appearance: ON = **red** |
| `DAQ CONNECTED?`, `Power Supply Connected?`, `DC Load Connected?` | **Silver ▸ Boolean ▸ Round LED** | Leave OFF colour grey. Simulation never sets these to TRUE |
| `SOC (%)`, `DC Voltage (V)`, `DC Current (A)`, `Temperature (degC)`, `Elapsed Time (s)`, `Cycle Count` | **Silver ▸ Numeric ▸ Numeric Indicator** | Right-click ▸ Display Format: 2 digits of precision (Cycle Count: 0) |
| `DC Voltage Graph`, `DC Current Graph`, `Temperature Graph` | **Silver ▸ Graph ▸ XY Graph** | X axis name `Time (s)`; Y axis names `Voltage (V)`, `Current (A)`, `Temperature (degC)`; right-click Y scale ▸ AutoScale Y on |
| `Status Message`, `Fault Message` | **Silver ▸ String & Path ▸ String Indicator** | Resize wider and taller; right-click ▸ Visible Items ▸ Vertical Scrollbar |
| `SIMULATION MODE` | **Silver ▸ String & Path ▸ String Indicator** | Make it wide; bold, large, orange text (see section 3) |
| `Operation Mode` | **Silver ▸ Ring & Enum ▸ Enum** | Only if it isn't already linked to `Test_State_Enum2.ctl`. **Skip** it if it is (it is, after step 3) |
| `Current State` | Leave it. It is linked to `Sim_State_Enum.ctl` | You can enlarge the font instead |
| `Charge Settings`, `Discharge Settings`, `Simulation Settings (DEMO ONLY)` | Leave the clusters as they are | You may recolour them and arrange their contents (right-click border ▸ AutoSizing ▸ Arrange Vertically) |

**Checks after section 1:** the Run arrow is solid. On the block diagram, open the Event Structure and step through its cases. They should still be named "Start": Value Change, "Stop": Value Change, and so on, with no case marked broken.

---

## 2. Arrange the panel

Suggested layout for a 1366×768 or larger screen:

```
+-----------------------------------------------------------------------------------+
| SIMULATION MODE banner (wide)   Current State   SOC  Elapsed  Cycle   [HW LEDs x3] |
+---------------------+---------------------------+---------------------------------+
| Operation Mode      | DC Voltage  DC Current    |  DC Voltage Graph               |
| [Start] [Stop]      | Temperature               |                                 |
| [Reset Fault]       | Sim PS LED  Sim Load LED  +---------------------------------+
| [Save]  [Close]     | Fault LED                 |  DC Current Graph               |
|                     |                           |                                 |
| Charge Settings     | Status Message (big)      +---------------------------------+
| Discharge Settings  | Fault Message             |  Temperature Graph              |
+---------------------+---------------------------+---------------------------------+
| Simulation Settings (DEMO ONLY) - collapsed below the fold, or in a corner         |
+-----------------------------------------------------------------------------------+
```

How to do it quickly:
- **Move:** drag the control by its edge. Arrow keys move 1 px; Shift + arrow moves 8 px.
- **Align and distribute:** select several controls (drag a box or Shift+click), then use the toolbar's **Align Objects** (e.g. Left Edges, Top Edges) and **Distribute Objects** (e.g. Vertical Gap).
- **Resize the same:** use the **Resize Objects** toolbar button (Maximum Width / Height) for the 3 graphs and for the buttons.
- **Group:** with a section aligned, use **Reorder ▸ Group** so it moves as one block.

---

## 3. Colours and text

1. **View ▸ Tools Palette**, then select the **Set Color** tool (the paintbrush).
2. **Panel background:** right-click an empty area of the panel with the paintbrush, then choose a dark grey, e.g. RGB 38,38,38.
3. **Labels:** select a label, open the **Text Settings** menu (toolbar font dropdown) ▸ **Color**, and choose white or light grey. Select several labels with Shift+click to do them together.
4. **SIMULATION MODE banner:** Text Settings ▸ Size 18–24, **Bold**, orange colour. Optionally paint the indicator background dark red.
5. **Decorations** (optional): Silver ▸ Decorations ▸ a flat box behind each section gives clean group frames. Right-click it ▸ **Reorder ▸ Move to Back**.

---

## 4. Window settings (optional)

**File ▸ VI Properties ▸ Window Appearance ▸ Customize**:
- Untick **Show toolbar when running** and **Show scroll bars** if the layout fits the screen.
- Tick **Show front panel when called** and **Close afterwards if originally closed**.

**File ▸ VI Properties ▸ Window Size**: set to your screen size (e.g. 1366×768), or tick **Maintain proportions of window for different monitor resolutions**.

---

## 5. Finish and check

1. **Ctrl+S**.
2. Run the VI. Within one second you should see **IDLE**, Status "Initialized. SIMULATION MODE …", SOC 50, both Sim output LEDs OFF.
3. Press **Close**. The VI must stop on its own, without the Abort button.
4. Tell Claude **"UI done"**. Claude then saves a picture of your panel (`Build\Tools_LV2019\panel_png.vbs`) and re-runs the startup test to confirm nothing broke.

If anything breaks, close the VI without saving, or go back to `Battery_Test_System_Main_before_UI.vi`.
