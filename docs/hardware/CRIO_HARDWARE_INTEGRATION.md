# cRIO Hardware Integration Guide (future phase)

This guide takes the **tested LabVIEW 2019 simulation** to a real battery test bench on the existing **NI cRIO-9063** with **NI 9205 / 9219 / 9263 / 9401**.

> ⚠️ **SAFETY FIRST.** A lithium-ion pack can deliver very high short-circuit current and can catch fire.
> - The software checks in this project are **simulation checks only**. They are **not** a battery management system and **not** a safety interlock.
> - The real bench needs **hardware** protection: a fuse at the battery, a BMS, a hard-wired emergency stop, and contactors that physically cannot close at the same time.
> - Have the wiring checked by a qualified person before connecting a battery.
>
> **Verify every terminal number against the module's front label and the NI Operating Instructions / Getting Started guide for your exact module variant** (spring terminal vs. DSUB) before wiring. The terminal numbers below are the commonly used layout, given for planning; the **channel names** are what the software uses.

---

## 1. Hardware you need

### Already available
| Item | Role |
|---|---|
| NI cRIO-9063 (chassis + RT controller) | Runs the real-time I/O loop |
| NI 9205 (slot 1) | 16 differential / 32 single-ended analog inputs, ±10 V max: battery voltage (through a divider) |
| NI 9219 (slot 2) | 4 isolated universal inputs: shunt voltage (current) and thermocouples |
| NI 9263 (slot 3) | 4 analog outputs, ±10 V, low current: setpoints for the supply and the load |
| NI 9401 (slot 4) | 8 TTL digital I/O (5 V, DSUB-25): enables, contactors, status inputs |

### To buy or confirm
| # | Item | Recommended spec | Why |
|---|---|---|---|
| 1 | **24 V DC supply for the cRIO** | 24 V, ≥ 2 A (cRIO-9063 accepts 9–30 V) | Powers the controller and modules |
| 2 | **Battery pack with BMS** | Confirm the chemistry and series count first, e.g. 4S LiFePO4 (12.8 V nominal, 14.6 V max) or 3S NMC (11.1 V nominal, 12.6 V max) | Sets the real voltage limits; the BMS is the primary protection |
| 3 | **Programmable DC power supply** | Above the pack's max charge voltage (e.g. ≥ 20 V), current ≥ max charge current, with an **analog programming input (0–5 V or 0–10 V)** and a **remote output-enable input** | Charging, controlled by NI 9263 + NI 9401 |
| 4 | **Programmable DC electronic load** | ≥ pack voltage, ≥ max discharge current and power, with an **analog current-programming input** and a **remote enable input** | Discharging, controlled by NI 9263 + NI 9401 |
| 5 | **Current shunt** | e.g. 50 A / 75 mV (1.5 mΩ) or 20 A / 75 mV, 0.25 % or better | Current measurement on NI 9219 (±125 mV range) |
| 6 | **Thermocouples** | Type K, self-adhesive or ring-lug, at least 2 (cell surface + ambient) | Temperature on NI 9219 (built-in cold-junction compensation) |
| 7 | **Voltage divider** (only if you use NI 9205 for battery voltage) | e.g. R1 = 20 kΩ, R2 = 10 kΩ, 0.1 %, ≥ 0.25 W → ÷3 (14.6 V → 4.87 V) | NI 9205 inputs are limited to ±10 V |
| 8 | **Two DC contactors / relays** | Rated for the max battery current at DC; coil 12 V or 24 V | Physically separate the charge path and the discharge path |
| 9 | **Relay driver / opto-isolated relay board** | 5 V TTL input, ≥ 4 channels | The NI 9401 output cannot drive relay coils directly |
| 10 | **Emergency-stop button** | Mushroom head, NC contact, latching | Hard-wired: cuts the contactor coil supply |
| 11 | **Battery fuse** | DC-rated, sized for the cable and the max current, mounted at the battery + terminal | Short-circuit protection |
| 12 | Cables, ferrules, DSUB-25 breakout for NI 9401, cable lugs, enclosure | Appropriate cross-sections | Wiring |

---

## 2. Power-path wiring (overview)

```
                    +--------- FUSE ---------+
 Battery + ---------|                        |---- Shunt (+ side) ---+
                                                                     |
                     +-------- K1 (charge) --------- PSU +           |
 node "BATT+" -------+                                               |
                     +-------- K2 (discharge) ------ LOAD +          |
                                                                     |
 Battery - ---- Shunt ---------------------------------------- PSU - and LOAD -
              (measure across the shunt with NI 9219 CH0)

 K1 and K2 coils: driven from the relay board (NI 9401 DIO2 / DIO3).
 Coil supply goes THROUGH the E-stop NC contact AND through the NC auxiliary contact
 of the other contactor (hardware interlock: K1 and K2 can never be closed together).
```

Put the shunt in the **negative** (low-side) lead so its voltage stays close to ground. NI 9219 channels are isolated, so a high-side shunt also works.

---

## 3. Signal wiring: module by module

### NI 9205, slot 1: battery voltage
| Signal | Channel | Wiring | Range / mode |
|---|---|---|---|
| Battery voltage (divided ÷3) | **AI0** (differential: AI0 = +, **AI8** = −) | Divider output → AI0, battery − (divider bottom) → AI8 | ±10 V, differential |
| Spare | AI1/AI9 … | – | – |
| Reference | **COM** | Connect COM to battery − through a 10 kΩ … 100 kΩ resistor (keeps the inputs within the common-mode range) | – |

Scaling: `V_batt = V_AI0 × (R1 + R2) / R2` (= × 3 for 20 k / 10 k).

> **Alternative without a divider:** measure battery voltage on **NI 9219 CH3** in its **±15 V** range: HI = battery +, LO = battery −. It's simpler and isolated, but slower.

### NI 9219, slot 2: current and temperature
Each channel has 6 terminals (commonly 1 = T+, 2 = T−, 3 = EX+, 4 = HI, 5 = LO, 6 = EX−; **verify on your module**).

| Signal | Channel | Terminals | Mode / range |
|---|---|---|---|
| Shunt voltage (battery current) | **CH0** | HI = shunt battery side, LO = shunt load side | Voltage, **±125 mV** |
| Battery cell temperature | **CH1** | HI = TC + (yellow, type K), LO = TC − (red, type K) | Thermocouple, **Type K**, internal CJC |
| Ambient temperature | **CH2** | HI = TC +, LO = TC − | Thermocouple, Type K |
| (optional) Battery voltage | **CH3** | HI = battery +, LO = battery − | Voltage, ±15 V |

Scaling: `I_batt = V_CH0 / R_shunt`. For example, 50 A / 75 mV gives R = 0.0015 Ω, so 75 mV corresponds to 50 A. The sign shows charge vs. discharge.

### NI 9263, slot 3: analog setpoints
Spring-terminal layout, commonly **0 = AO0, 1 = COM, 2 = AO1, 3 = COM, 4 = AO2, 5 = COM, 6 = AO3, 7 = COM**.

| Signal | Channel | Goes to | Scaling (example) |
|---|---|---|---|
| Power supply **voltage** setpoint | **AO0** / COM | PSU analog V-program input | 0–10 V = 0–V_max(PSU); check the PSU manual |
| Power supply **current limit** | **AO1** / COM | PSU analog I-program input | 0–10 V = 0–I_max(PSU) |
| Electronic load **current** setpoint | **AO2** / COM | LOAD analog I-program input | 0–10 V = 0–I_max(LOAD) |
| Spare | AO3 | – | – |

> NI 9263 outputs are low-current (a few mA) and are **not** a power source. If the PSU or load programming input is not isolated, add an **isolation amplifier** to avoid ground loops.

### NI 9401, slot 4: digital I/O (5 V TTL, DSUB-25)
Direction is set **per nibble**: DIO0–3 = **outputs**, DIO4–7 = **inputs** (configure this in the project's module properties). **Take the DSUB-25 pin numbers from the NI 9401 pinout in its Operating Instructions.**

| Signal | Line | Dir | Connect to |
|---|---|---|---|
| PSU output enable | **DIO0** | out | Relay board ch1 → PSU remote-enable input |
| LOAD input enable | **DIO1** | out | Relay board ch2 → LOAD remote-enable input |
| Charge contactor K1 coil | **DIO2** | out | Relay board ch3 → K1 coil (through E-stop + K2-NC) |
| Discharge contactor K2 coil | **DIO3** | out | Relay board ch4 → K2 coil (through E-stop + K1-NC) |
| E-stop status (released = 1) | **DIO4** | in | Second E-stop contact → 5 V pull-up |
| BMS OK | **DIO5** | in | BMS "OK/no-fault" output via opto-isolator |
| PSU ready / connected | **DIO6** | in | PSU status output via opto-isolator |
| LOAD ready / connected | **DIO7** | in | Load status output via opto-isolator |
| Ground | **COM** pins | – | Relay board and opto-isolator ground |

> NI 9401 lines are 5 V TTL with limited current. **Never** connect relay coils, 12/24 V signals or the battery directly; always go through the relay board or opto-isolators.

---

## 4. How the signals map to the software

| Software field (`Sim_Data.ctl`) | Today (simulation) | Hardware source |
|---|---|---|
| `Voltage (V)` | model | NI 9205 AI0 × divider ratio (or NI 9219 CH3) |
| `Current (A)` | model | NI 9219 CH0 / R_shunt |
| `Temperature (degC)` | model | NI 9219 CH1 |
| `Sim PS Enable` | interlock in model | → NI 9401 DIO0 **and** DIO2 (K1) |
| `Sim Load Enable` | interlock in model | → NI 9401 DIO1 **and** DIO3 (K2) |
| `Setpoint Voltage (V)` / `Setpoint Current (A)` | user setpoints | → NI 9263 AO0 / AO1 (charge) or AO2 (discharge) |
| `Power Supply Connected?` / `DC Load Connected?` LEDs | always FALSE | NI 9401 DIO6 / DIO7 |
| `DAQ CONNECTED?` LED | always FALSE | TRUE when the cRIO I/O loop is running and reachable |
| `Inject E-Stop` (fault source 1) | demo switch | E-stop pressed = **NOT(DIO4)** |
| new: BMS fault | – | BMS fault = **NOT(DIO5)** |

---

## 5. Software steps (LabVIEW 2019)

1. **Install on the PC:** LabVIEW 2019 Real-Time Module + NI CompactRIO / NI-RIO driver (the version matching LabVIEW 2019). Use NI MAX to install the same software set on the cRIO-9063.
2. **In the project:** the cRIO target already has **Real-Time Scan Resources** with Mod1–Mod4. Set:
   - NI 9219: CH0 = Voltage ±125 mV; CH1/CH2 = Thermocouple Type K
   - NI 9205: differential mode (or the ±15 V channel on the 9219)
   - NI 9401: DIO0–3 output, DIO4–7 input
3. **New VI `HW_IO_Update.vi` (under the cRIO target)** with the **same connector pane as `Sim_Update_Model.vi`** (Sim Data in, Settings, State, dt → Sim Data out):
   - Read the scan-engine I/O variables (`Mod1/AI0`, `Mod2/CH0`, `Mod2/CH1`, …), scale them, and bundle them into Sim Data.
   - Compute the outputs **only** from the interlocked `Sim PS Enable` / `Sim Load Enable` flags. Write AO0–AO2 and DIO0–DIO3 accordingly.
   - Force all outputs OFF on any error, in FAULT, and on loop exit.
4. **Architecture:** run the I/O + safety loop **on the cRIO** (deterministic and keeps running if the PC disconnects), and keep the UI on the PC. Communicate through network-published shared variables or network streams. The existing state machine and the safety, completion and CSV subVIs can be reused as they are.
5. **Real limits:** replace the DEMO values in `Simulation Settings` with the limits from the **battery datasheet and BMS**. Keep the hardware protection anyway.
6. **Bring-up order** (never skip):
   1. Without a battery: check every input with a known source. Check every output with a multimeter; the contactors must not click together.
   2. Check the E-stop: pressing it must open both contactors with the software still running.
   3. With a **dummy load / lab supply** instead of the battery: low-current charge and discharge.
   4. Only then with the battery, at low C-rate, while supervised.

---

## 6. Wiring checklist (print it)

- [ ] Fuse at battery +, rated for DC and the max current
- [ ] Shunt in the battery − lead; NI 9219 CH0 HI/LO across it
- [ ] K1 / K2 coil circuits pass through the E-stop NC contact **and** the other contactor's NC auxiliary contact
- [ ] NI 9205 input voltage < 10 V at max battery voltage (divider checked with a multimeter)
- [ ] NI 9263 AO0–AO2 → programming inputs (isolated if needed); scaling noted from the PSU and load manuals
- [ ] NI 9401 → relay board / opto-isolators only; DIO0–3 out, DIO4–7 in
- [ ] Thermocouple polarity correct (type K: yellow +, red −); reads room temperature
- [ ] cRIO powered from its own 24 V supply; chassis grounded
- [ ] All DEMO limits replaced with real datasheet limits
