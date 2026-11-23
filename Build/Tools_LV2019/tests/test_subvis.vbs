' Usage: cscript //nologo test_subvis.vbs <folder holding the subVIs> <scratch folder for CSV>
' Runs Sim_Update_Model, Sim_Check_Safety, Sim_Check_Completion and Sim_Save_CSV in LabVIEW 2019
' with known inputs and checks the outputs against hand-computed expectations.
' Sim Data cluster index map (0-based):
'  0 SOC 1 V 2 I 3 T 4 RunTime 5 Elapsed 6 Cycle 7 ActiveMode 8 Vset 9 Iset 10 Crate 11 Dur
' 12 PS 13 Load 14 CHD 15 DHD 16 Fault 17 FaultCode 18 FaultMsg 19 FaultTime 20 Status
On Error Resume Next
Dim lv, dir, scratch, fails, total
dir = WScript.Arguments(0) : scratch = WScript.Arguments(1)
Set lv = CreateObject("LabVIEW.Application")
fails = 0 : total = 0

Function SD(soc, v, i, t, el, cyc, vset, iset, crate, dur, ps, ld, chd, dhd, flt, ftime)
  SD = Array(CDbl(soc), CDbl(v), CDbl(i), CDbl(t), CDbl(0), CDbl(el), CLng(cyc), CInt(0), CDbl(vset), CDbl(iset), CDbl(crate), CDbl(dur), CBool(ps), CBool(ld), CBool(chd), CBool(dhd), CBool(flt), CLng(0), "", CStr(ftime), "")
End Function
Function ST(ie, iov, ioc, iot)
  ST = Array(CLng(200), CDbl(1), CDbl(50), CDbl(12), CDbl(25), CDbl(5), CDbl(1), CDbl(120), CDbl(0.002), CDbl(1), CDbl(100), CDbl(0), CDbl(15), CDbl(10), CDbl(45), CDbl(5), CDbl(600), CLng(3000), CBool(ie), CBool(iov), CBool(ioc), CBool(iot))
End Function
Sub Check(name, cond, detail)
  total = total + 1
  If cond Then
    WScript.Echo "  PASS " & name & "  " & detail
  Else
    fails = fails + 1 : WScript.Echo "  FAIL " & name & "  " & detail
  End If
End Sub
Function Near(a, b) : Near = Abs(CDbl(a) - CDbl(b)) < 0.0001 : End Function
' VBScript cannot touch a U32 (Cycle Count, index 6). Read it by passing the cluster through
' Sim_Save_CSV.vi and taking the CycleCount column of the written row.
Function CycleOf(simData)
  Dim wv, fs, pth, lines, cols
  Set fs = CreateObject("Scripting.FileSystemObject")
  pth = scratch & "\cycle_probe.csv"
  If fs.FileExists(pth) Then fs.DeleteFile pth
  Set wv = lv.GetVIReference(dir & "\Sim_Save_CSV.vi", "", False, 0)
  wv.SetControlValue "Log Records", Array(Array("probe", CInt(0), simData))
  wv.SetControlValue "File Path (empty = dialog)", pth
  wv.Run False
  Set wv = Nothing
  lines = Split(fs.OpenTextFile(pth).ReadAll, vbCrLf)
  cols = Split(lines(1), ",")
  CycleOf = CLng(cols(9))
End Function
Function OpenVI(n)
  Err.Clear
  Set OpenVI = lv.GetVIReference(dir & "\" & n, "", False, 0)
  If Err.Number <> 0 Then WScript.Echo "OPEN FAILED " & n & ": " & Err.Description : WScript.Quit 1
End Function
Sub RunIt(vi, n)
  Err.Clear
  vi.Run False
  If Err.Number <> 0 Then WScript.Echo "RUN FAILED " & n & " (VI broken?): " & Err.Description : WScript.Quit 2
End Sub

' ---------------- Sim_Update_Model ----------------
WScript.Echo "Sim_Update_Model.vi"
Dim m, o
Set m = OpenVI("Sim_Update_Model.vi")
m.SetControlValue "Settings", ST(False, False, False, False)
m.SetControlValue "dt (s)", CDbl(1)
' A: CHARGING from SOC 50, V 12, I 0, T 25, Vset 14, Iset 5, C 1
m.SetControlValue "Sim Data in", SD(50, 12, 0, 25, 0, 0, 14, 5, 1, 10, False, False, False, False, False, "")
m.SetControlValue "State", CInt(2)
RunIt m, "Model"
o = m.GetControlValue("Sim Data out")
Check "charge SOC", Near(o(0), 50 + 100 / 3600), "SOC=" & o(0)
Check "charge V (first order, tau 5 s)", Near(o(1), 12.4), "V=" & o(1)
Check "charge I", Near(o(2), 5), "I=" & o(2)
Check "charge T (I^2 heating)", Near(o(3), 25.05), "T=" & o(3)
Check "charge run/elapsed time", Near(o(4), 1) And Near(o(5), 1), "rt=" & o(4) & " el=" & o(5)
Check "charge interlock PS on, Load off", o(12) = True And o(13) = False, "PS=" & o(12) & " Load=" & o(13)
' B: DISCHARGING, Vset 11, Iset 5
m.SetControlValue "Sim Data in", SD(50, 12, 0, 25, 0, 0, 11, 5, 1, 10, False, False, False, False, False, "")
m.SetControlValue "State", CInt(3)
RunIt m, "Model"
o = m.GetControlValue("Sim Data out")
Check "discharge SOC", Near(o(0), 50 - 100 / 3600), "SOC=" & o(0)
Check "discharge V", Near(o(1), 11.8), "V=" & o(1)
Check "discharge I negative", Near(o(2), -5), "I=" & o(2)
Check "discharge interlock PS off, Load on", o(12) = False And o(13) = True, "PS=" & o(12) & " Load=" & o(13)
' C: IDLE with stale outputs and current -> all off, current 0, SOC unchanged, elapsed frozen
m.SetControlValue "Sim Data in", SD(50, 14, 5, 25, 7, 0, 14, 5, 1, 10, True, True, False, False, False, "")
m.SetControlValue "State", CInt(1)
RunIt m, "Model"
o = m.GetControlValue("Sim Data out")
Check "idle SOC hold", Near(o(0), 50), "SOC=" & o(0)
Check "idle V relaxes to rest 12 V", Near(o(1), 13.6), "V=" & o(1)
Check "idle I forced 0", Near(o(2), 0), "I=" & o(2)
Check "idle elapsed frozen", Near(o(5), 7), "el=" & o(5)
Check "idle both outputs OFF", o(12) = False And o(13) = False, "PS=" & o(12) & " Load=" & o(13)
' D: SOC clamp at 100
m.SetControlValue "Sim Data in", SD(99.99, 14, 5, 25, 0, 0, 14, 5, 5, 10, False, False, False, False, False, "")
m.SetControlValue "State", CInt(2)
RunIt m, "Model"
o = m.GetControlValue("Sim Data out")
Check "SOC clamped to 100", Near(o(0), 100), "SOC=" & o(0)
Set m = Nothing

' ---------------- Sim_Check_Safety ----------------
WScript.Echo "Sim_Check_Safety.vi"
Dim s
Set s = OpenVI("Sim_Check_Safety.vi")
s.SetControlValue "Settings", ST(False, False, False, False)
s.SetControlValue "Sim Data in", SD(50, 14, 5, 30, 0, 0, 14, 5, 1, 10, True, False, True, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "normal: no fault, data unchanged", s.GetControlValue("Fault Active?") = False And o(12) = True And o(14) = True, "fault=" & s.GetControlValue("Fault Active?") & " PS=" & o(12)
s.SetControlValue "Sim Data in", SD(50, 16, 5, 30, 0, 0, 14, 5, 1, 10, True, False, True, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "overvoltage -> code 2, outputs OFF, flags cleared", s.GetControlValue("Fault Active?") = True And o(16) = True And o(17) = 2 And o(12) = False And o(14) = False, "code=" & o(17) & " msg=""" & o(18) & """ time=" & o(19)
s.SetControlValue "Sim Data in", SD(50, 14, -11, 30, 0, 0, 14, 5, 1, 10, False, True, False, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "overcurrent (|-11| A) -> code 3", o(17) = 3, "code=" & o(17)
s.SetControlValue "Sim Data in", SD(50, 14, 5, 46, 0, 0, 14, 5, 1, 10, True, False, False, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "overtemperature -> code 4", o(17) = 4, "code=" & o(17)
s.SetControlValue "Sim Data in", SD(50, 14, 5, 30, 0, 0, 14, 5, 1, 10, True, True, False, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "interlock (PS and Load) -> code 5", o(17) = 5, "code=" & o(17) & " msg=""" & o(18) & """"
s.SetControlValue "Settings", ST(True, False, False, False)
s.SetControlValue "Sim Data in", SD(50, 16, 5, 30, 0, 0, 14, 5, 1, 10, False, False, False, False, True, "2000-01-01 00:00:00")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "E-Stop has priority over OV (code 1), first fault time kept", o(17) = 1 And o(19) = "2000-01-01 00:00:00", "code=" & o(17) & " time=" & o(19)
s.SetControlValue "Settings", ST(False, True, False, False)
s.SetControlValue "Sim Data in", SD(50, 12, 0, 25, 0, 0, 14, 5, 1, 10, False, False, False, False, False, "")
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "OV injection with normal values -> code 2", o(17) = 2, "code=" & o(17) & " status=""" & o(20) & """"
Dim sdl : sdl = SD(50, 12, 0, 25, 0, 0, 14, 5, 1, 10, False, False, False, False, True, "2000-01-01 00:00:00")
sdl(20) = "Start blocked: fault latched."
s.SetControlValue "Sim Data in", sdl
RunIt s, "Safety"
o = s.GetControlValue("Sim Data out")
Check "already latched fault keeps the status text", o(20) = "Start blocked: fault latched." And o(16) = True, "status=""" & o(20) & """"
Set s = Nothing

' ---------------- Sim_Check_Completion ----------------
WScript.Echo "Sim_Check_Completion.vi"
Dim c
Set c = OpenVI("Sim_Check_Completion.vi")
c.SetControlValue "Settings", ST(False, False, False, False)
c.SetControlValue "State", CInt(2)
c.SetControlValue "Sim Data in", SD(60, 14, 5, 25, 10, 0, 14, 5, 1, 10, True, False, False, False, False, "")
RunIt c, "Completion"
o = c.GetControlValue("Sim Data out")
Check "charging, SOC 60, 10 s of 10 min -> not done", c.GetControlValue("Done?") = False And o(14) = False, "done=" & c.GetControlValue("Done?")
c.SetControlValue "Sim Data in", SD(100, 14, 5, 25, 10, 0, 14, 5, 1, 10, True, False, False, False, False, "")
RunIt c, "Completion"
o = c.GetControlValue("Sim Data out")
Check "charging, SOC 100 -> done, charge half set", c.GetControlValue("Done?") = True And o(14) = True And CycleOf(o) = 0, "CHD=" & o(14) & " cyc=" & CycleOf(o) & " msg=""" & o(20) & """"
c.SetControlValue "State", CInt(3)
c.SetControlValue "Sim Data in", SD(0, 11, -5, 25, 10, 0, 11, 5, 1, 10, False, True, True, False, False, "")
RunIt c, "Completion"
o = c.GetControlValue("Sim Data out")
Check "discharging to 0 after charge half -> cycle 1, flags cleared", CycleOf(o) = 1 And o(14) = False And o(15) = False, "cyc=" & CycleOf(o) & " msg=""" & o(20) & """"
c.SetControlValue "State", CInt(2)
c.SetControlValue "Sim Data in", SD(60, 14, 5, 25, 601, 0, 14, 5, 1, 10, True, False, False, False, False, "")
RunIt c, "Completion"
o = c.GetControlValue("Sim Data out")
Check "duration elapsed -> done, half NOT counted", c.GetControlValue("Done?") = True And o(14) = False And CycleOf(o) = 0, "CHD=" & o(14) & " msg=""" & o(20) & """"
Set c = Nothing

' ---------------- Sim_Save_CSV ----------------
WScript.Echo "Sim_Save_CSV.vi"
Dim w, recs, p, fso, txt
Set fso = CreateObject("Scripting.FileSystemObject")
Set w = OpenVI("Sim_Save_CSV.vi")
recs = Array( _
  Array("2026-11-23 12:00:00.000", CInt(1), SD(50, 12, 0, 25, 0, 0, 14, 5, 1, 10, False, False, False, False, False, "")), _
  Array("2026-11-23 12:00:00.200", CInt(2), SD(50.0278, 12.4, 5, 25.05, 0.2, 0, 14, 5, 1, 10, True, False, False, False, False, "")))
p = scratch & "\test_log.csv"
If fso.FileExists(p) Then fso.DeleteFile p
w.SetControlValue "Log Records", recs
w.SetControlValue "File Path (empty = dialog)", p
RunIt w, "Save"
Check "save to new file -> Saved?", w.GetControlValue("Saved?") = True, "status=""" & w.GetControlValue("Status Message") & """"
If fso.FileExists(p) Then
  txt = fso.OpenTextFile(p).ReadAll
  WScript.Echo "  ---- file content ----" & vbCrLf & txt & "  ----------------------"
  Check "CSV header + 2 rows", UBound(Split(txt, vbCrLf)) = 3 And Right(txt, 2) = vbCrLf And InStr(txt, "Timestamp,RunTime_s") = 1, "(3 lines, each ending CRLF)"
  Check "enum names written (IDLE, CHARGING, Charge)", InStr(txt, ",IDLE,Charge,") > 0 And InStr(txt, ",CHARGING,Charge,") > 0, ""
End If
w.SetControlValue "File Path (empty = dialog)", "C:\Windows\System32\sim_test_denied.csv"
RunIt w, "Save"
Check "unwritable path -> Saved? false with error message", w.GetControlValue("Saved?") = False And InStr(w.GetControlValue("Status Message"), "Save FAILED") = 1, "status=""" & w.GetControlValue("Status Message") & """"
Set w = Nothing

WScript.Echo fails & " failure(s) of " & total
