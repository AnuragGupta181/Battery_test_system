' Usage: cscript //nologo test_Sim_Validate_Setpoints.vbs <path to Sim_Validate_Setpoints.vi>
' Runs the VI in LabVIEW 2019 with the Settings defaults (max 15 V, 10 A, 5 /h, 600 min)
' and compares Valid? / Message against expectations.
On Error Resume Next
Dim lv, vi, cases, c, k, valid, msg, pass, fails
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(CStr(WScript.Arguments(0)), "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN FAILED: " & Err.Description : WScript.Quit 1
' V, I, C, D, expected Valid?, expected message fragment
cases = Array( _
  Array(14, 5, 1, 10, True, "Setpoints OK."), _
  Array(15, 10, 5, 600, True, "Setpoints OK."), _
  Array(14, 0, 1, 10, False, "Current setpoint"), _
  Array(14, -1, 1, 10, False, "Current setpoint"), _
  Array(16, 5, 1, 10, False, "Voltage setpoint"), _
  Array(14, 5, 6, 10, False, "C-Rate must"), _
  Array(14, 5, 1, 601, False, "Duration must"), _
  Array(0, 0, 0, 0, False, "Voltage setpoint"), _
  Array(14, 5, 0.001, 0.01, True, "Setpoints OK."))
fails = 0
For k = 0 To UBound(cases)
  c = cases(k)
  Err.Clear
  vi.SetControlValue "Voltage (V)", CDbl(c(0))
  vi.SetControlValue "Current (A)", CDbl(c(1))
  vi.SetControlValue "C-Rate (1/h)", CDbl(c(2))
  vi.SetControlValue "Duration (min)", CDbl(c(3))
  vi.Run False
  If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
  valid = vi.GetControlValue("Valid?")
  msg = vi.GetControlValue("Message")
  pass = (CBool(valid) = c(4)) And (InStr(msg, c(5)) > 0)
  If Not pass Then fails = fails + 1
  WScript.Echo IIf(pass, "PASS", "FAIL") & "  V=" & c(0) & " I=" & c(1) & " C=" & c(2) & " D=" & c(3) & "  -> Valid?=" & valid & "  Message=""" & msg & """"
Next
WScript.Echo fails & " failure(s) of " & (UBound(cases) + 1)
Set vi = Nothing
Function IIf(b, t, f)
  If b Then IIf = t Else IIf = f
End Function
