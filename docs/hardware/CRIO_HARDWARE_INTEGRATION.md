# cRIO Hardware Integration Guide: low-cost 4S bench (future phase)

This guide takes the **tested LabVIEW 2019 simulation** to a small, low-cost battery bench. It uses the lab's existing **NI cRIO-9063** with its **NI 9205 / 9219 / 9263 / 9401** modules.

The pack is **4 × 18650 Li-ion cells (2000 mAh) in series (4S) with a BMS**. A **fixed 16.8 V Li-ion charger** charges it, and a **12 V bulb plus a resistor** discharges it. Two relays switch them in and out under software control.

> ⚠️ **SAFETY FIRST.** Li-ion cells can deliver high short-circuit current and can catch fire.
> - The software limits in this project are **demonstration checks**, not certified protection.
> - The **BMS**, the **fuse**, the **E-stop switch** and the **relay interlock** are the real protection.
> - Generic cells with no datasheet are the biggest risk. Charge on a non-flammable surface, and never leave the bench unattended while charging.
> - Have the wiring checked by a qualified person before connecting the pack.
>
> **Verify every terminal number** against the module's front label and the NI Operating Instructions for your module variant before wiring. The terminal numbers below are for planning; the **channel names** are what the software uses.

---

## 1. Pack data (4S, 2000 mAh cells)

| | Per cell | 4S pack |
|---|---|---|
| Full charge | 4.2 V | **16.8 V** |
| Nominal | 3.7 V | **14.8 V** |
| Software discharge stop | 3.0 V | **12.0 V** |
| Capacity | 2000 mAh (label; generic cells are often lower) | **2000 mAh** (series adds voltage, not capacity) |
| Charge current | | **1 A** (0.5C), fixed by the charger |
| Discharge current | | **~0.7–0.9 A** with one bulb set; ~1.8 A with two (≤ 1C) |

**Before assembling the pack:**
- Charge **each cell separately** to 4.2 V with the single-cell charger that comes with the cells.
- Check with a multimeter that all 4 cells are within **0.05 V** of each other (top balancing).
- **Never** charge the assembled 4S pack with the single-cell charger.

---

## 2. Hardware

### Already in the lab (not bought)
| Item | Used for |
|---|---|
| NI cRIO-9063 + its 24 V supply | Real-time I/O and safety loop |
| NI 9219 (slot 2) | **All measurements:** current (shunt), temperature (thermocouple), pack voltage (±60 V range) |
| NI 9401 (slot 4) | Relay control (charger, load) and the optional E-stop status input |
| NI 9205 (slot 1) | **Not used.** Optional later: per-cell voltages (cell taps need dividers, since the inputs are ±10 V max) |
| NI 9263 (slot 3) | **Not used.** The charger and the bulb have no analog setpoint input |

### To buy (approx. Indian prices)
| # | Item | Spec | Approx. ₹ |
|---|---|---|---|
| 1 | 18650 Li-ion cells | 4 cells, same batch (2 × 2-cell combo packs) | ~560 |
| 2 | **4S BMS with balancing** | 4S, 16.8 V, 10–20 A, with balance leads | 150–250 |
| 3 | 4 × 18650 **series** holder, with leads | Or nickel strip spot-welded by a shop. **Don't solder the cells.** | 80–150 |
| 4 | **16.8 V Li-ion charger adapter** | 16.8 V, **1 A**, CC/CV with auto cut-off | 350–500 |
| 5 | **Load:** 12 V 10 W bulb + holder | Wired in series with item 6 | 50–80 |
| 6 | **4.7 Ω, 10 W** resistor | Series with the bulb (see §5). One more bulb + resistor set if you want 2× discharge speed. | 20–40 |
| 7 | **Shunt resistor: 0.05 Ω (50 mΩ)** | 1 %, ≥ 2 W | 20–60 |
| 8 | **1 × type K thermocouple** | Adhesive or washer tip | 120–200 |
| 9 | **2-channel opto-isolated relay module**, 5 V | SPDT contacts (COM / NO / NC), ≥ 10 A | 80–120 |
| 10 | 5 V USB adapter for the relay module | Any phone charger | usually on hand |
| 11 | Inline fuse holder + **3 A** fuse | At the pack + output | 40–60 |
| 12 | E-stop or toggle switch | NC contact. A 2-contact mushroom also feeds the status input (optional). | 30–250 |
| 13 | Wire (18 AWG power, thin for sensing), terminal block, DSUB-25 breakout for NI 9401 | | 100–250 |
| | **Total** | | **≈ ₹1,600 – 2,400** |

### Removed from the earlier plan, and why
| Removed | Reason |
|---|---|
| Programmable DC power supply | Replaced by the fixed 16.8 V charger, which does CC/CV itself |
| Programmable electronic load | Replaced by the bulb + resistor load |
| 2 DC contactors + 4-channel relay board | One 2-channel relay module is enough at ~1 A |
| Second thermocouple (ambient) | Not needed: NI 9219 has built-in cold-junction compensation, and the software has an `Ambient Temp` setting |
| Voltage divider for NI 9205 | NI 9219 measures the pack directly in its ±60 V range |
| PSU / load "ready" and BMS-OK status inputs | The charger and cheap BMS boards have no status outputs |
| NI 9263 analog setpoints | Nothing to program |

**What you lose:** the software can no longer *set* the charge current or the load current. It switches the charger and the load on and off, measures everything, and stops on the limits.

---

## 3. Power-path wiring

```
 Cells B- ... B+  ==  BMS (B-, balance leads, P-)
                                           
 Pack + (B+) -- FUSE 3 A --+-- Relay 1 COM
                           |     Relay 1 NO ---------------- Charger +
                           |     Relay 1 NC -- Relay 2 COM
                           |                     Relay 2 NO -- Bulb -- 4.7 ohm -- (load end)
                                                                               
 BMS P- -- [ SHUNT 0.05 ohm ] -- common negative ---- Charger -  and  load end
             NI 9219 CH0 across the shunt

 Relay module VCC (5 V USB adapter) goes THROUGH the E-stop NC contact.
```

- **Hardware interlock:** relay 2 gets its supply from relay 1's **NC** contact. When relay 1 connects the charger, the load is physically disconnected, so the charger and the load can never be connected together, whatever the software does.
- **E-stop:** pressing it removes the relay module's 5 V, so both relays drop out, cutting off the charger and the load.
- **Shunt placement:** between BMS **P−** and the common negative of the charger and the load. One shunt then measures both directions.
- Put the **fuse** as close to the pack + as possible.

---

## 4. Signal wiring: module by module

### NI 9219, slot 2: all measurements
Each channel has 6 terminals (commonly 1 = T+, 2 = T−, 3 = EX+, 4 = HI, 5 = LO, 6 = EX−; **verify on your module**).

| Signal | Channel | Terminals | Mode / range |
|---|---|---|---|
| Pack current (shunt) | **CH0** | HI = shunt **P− side**, LO = shunt **common-negative side**. Connect the sense wires right at the resistor legs (Kelvin). | Voltage, **±125 mV** |
| Cell temperature | **CH1** | HI = TC + (yellow), LO = TC − (red) | Thermocouple, **Type K**, internal CJC |
| Pack voltage | **CH2** | HI = pack + (after fuse), LO = BMS P− | Voltage, **±60 V** (16.8 V is above the ±15 V range) |
| Spare | CH3 | – | – |

Scaling:
- `I_pack = V_CH0 / 0.05`. With this HI/LO, **charge is positive and discharge is negative**, which matches the software. If the sign comes out reversed, swap HI/LO or multiply by −1.
- At 2 A the shunt gives 100 mV, inside the 125 mV range. At 1 A it gives 50 mV. Shunt heat at 2 A is 0.2 W.
- Don't use 0.1 Ω: it would exceed 125 mV above 1.25 A.
- Fit the thermocouple on the **middle cells** of the pack, which are the hottest spot.

### NI 9401, slot 4: relays and E-stop (5 V TTL, DSUB-25)
Direction is set **per nibble**: DIO0–3 = outputs, DIO4–7 = inputs (set in the project's module properties). **Take the DSUB-25 pin numbers from the NI 9401 Operating Instructions.**

| Signal | Line | Dir | Connect to |
|---|---|---|---|
| Charger connect | **DIO0** | out | Relay module IN1 |
| Load connect | **DIO1** | out | Relay module IN2 |
| E-stop status (released = 1), optional | **DIO4** | in | Second E-stop contact → 5 V pull-up |
| Ground | **COM** | – | Relay module GND (input side) |

**Relay drive check:**
- Compare the NI 9401 output current in its datasheet with the relay module's input current. Opto inputs usually draw a few mA.
- If the 9401 can't supply it, add a **ULN2003** driver (about ₹30).
- Note whether the module is **active-low** (triggers on 0 V). If it is, invert DIO0/DIO1 in software so that "OFF" really is off at power-up.
- **Never** connect the battery or 12/24 V signals to the NI 9401.

### NI 9205 and NI 9263
Not used in this plan.

---

## 5. The bulb load

A 12 V bulb on a 16.8 V pack is 40 % overvolted, which shortens its life a lot. A **4.7 Ω, 10 W resistor in series** fixes that:

| Pack voltage | Current (approx.) | Bulb sees | Look |
|---|---|---|---|
| 16.8 V (full) | ~0.9 A | ~12.7 V | Bright |
| 14.8 V (nominal) | ~0.8 A | ~11 V | Normal |
| 12.0 V (stop) | ~0.7 A | ~8.7 V | Visibly dimmer |

- The resistor dissipates about 4 W, so it gets warm. Mount it away from the cells.
- One set takes about 2.5 h from full to 12 V. Two sets in parallel draw about 1.8 A and take about 1.2 h.
- The current is not constant (it falls with voltage). That is fine, because the software measures the real current.

---

## 6. How the signals map to the software

| Software field (`Sim_Data.ctl`) | Today (simulation) | Hardware source |
|---|---|---|
| `Voltage (V)` | model | NI 9219 CH2 |
| `Current (A)` | model | NI 9219 CH0 / 0.05 |
| `Temperature (degC)` | model | NI 9219 CH1 |
| `SOC (%)` | from C-rate | **Coulomb counting:** `SOC += I × dt / 3600 / Capacity_Ah × 100`, starting from 100 % after a full charge |
| `Sim PS Enable` | interlock in model | → NI 9401 **DIO0** (charger relay) |
| `Sim Load Enable` | interlock in model | → NI 9401 **DIO1** (load relay) |
| `Setpoint Voltage (V)` / `Setpoint Current (A)` | user setpoints | **Not used.** Fixed by the charger (16.8 V / 1 A) and the bulb |
| `Power Supply Connected?` / `DC Load Connected?` LEDs | always FALSE | Show the commanded DIO0 / DIO1 state |
| `DAQ CONNECTED?` LED | always FALSE | TRUE while the cRIO I/O loop is running and reachable |
| `Inject E-Stop` (fault source 1) | demo switch | E-stop pressed = **NOT(DIO4)** (if the second contact is wired) |

### Settings for this pack (demonstration values, not certified limits)
| Setting | Value |
|---|---|
| Charge complete | V ≥ 16.8 V **and** current < 0.1 A (the charger also cuts off itself) |
| Discharge complete | V ≤ **12.0 V** |
| Overvoltage fault | 17.0 V |
| Overcurrent fault | 2.5 A |
| Overtemperature fault | 45 °C |
| Capacity | 2.0 Ah (correct it after the first full measured discharge) |

The BMS cuts off at its own limits (typically about 4.25 V and 2.5–2.8 V per cell), which are outside the software limits, so the software always acts first.

---

## 7. Software steps (LabVIEW 2019)

1. **Install on the PC:** LabVIEW 2019 Real-Time Module + NI CompactRIO / NI-RIO driver matching LabVIEW 2019. Use NI MAX to install the same software set on the cRIO-9063.
2. **In the project:** under the cRIO target's **Real-Time Scan Resources**, set:
   - NI 9219: CH0 = Voltage ±125 mV; CH1 = Thermocouple Type K; CH2 = Voltage ±60 V
   - NI 9401: DIO0–3 output, DIO4–7 input
3. **New VI `HW_IO_Update.vi`** (under the cRIO target), with the **same connector pane as `Sim_Update_Model.vi`** (Sim Data in, Settings, State, dt → Sim Data out):
   - Read `Mod2/CH0`, `Mod2/CH1` and `Mod2/CH2`, scale them, and do the coulomb-counting SOC.
   - Write DIO0 and DIO1 **only** from the interlocked `Sim PS Enable` / `Sim Load Enable` flags.
   - Force both relays OFF on any error, in FAULT, and on loop exit.
4. **Architecture:** run the I/O + safety loop **on the cRIO** (deterministic, and it keeps running if the PC disconnects). Keep the UI on the PC, linked by network-published shared variables. The existing state machine and the safety, completion and CSV subVIs can be reused as they are.
5. **Bring-up order** (never skip a step):
   1. **No pack connected:**
      - Check the relays click on DIO0 and DIO1.
      - Confirm relay 2 cannot connect while relay 1 is on.
      - Check the E-stop drops both relays.
   2. **NI 9219 inputs:**
      - CH2 reads the charger output voltage correctly (compare with a multimeter).
      - CH1 reads room temperature.
      - CH0 reads about 0 with no current.
   3. **Pack connected, load only, short run:**
      - The current is negative and about 0.8 A.
      - The voltage falls slowly.
   4. **Charge, supervised:**
      - The current is positive and about 1 A.
      - It stops at 16.8 V.

---

## 8. Wiring checklist (print it)

- [ ] Cells top-balanced (within 0.05 V) before assembly; BMS balance leads in the right order
- [ ] 3 A fuse at pack +
- [ ] Relay 2 fed from relay 1's **NC** contact (hardware interlock)
- [ ] Relay module 5 V goes through the E-stop NC contact
- [ ] Shunt between BMS P− and the common negative; NI 9219 CH0 sense wires at the resistor legs
- [ ] NI 9219 CH2 set to ±60 V (not ±15 V)
- [ ] Thermocouple polarity correct (yellow +, red −), taped to the middle cells, reads room temperature
- [ ] NI 9401 drives only the relay module inputs (ULN2003 if needed); DIO0–3 out, DIO4–7 in
- [ ] Bulb resistor mounted away from the cells
- [ ] All DEMO limits replaced with the values in §6 (or the cell datasheet, if you have one)
