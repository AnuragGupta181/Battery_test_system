' Usage: cscript //nologo monitor_main.vbs <main.vi> <log.txt> [minutes]
' Opens the main VI's front panel in LabVIEW 2019, runs it, and logs every change of the key
' indicators (polled every 250 ms) until the Status shows "Closing"/"Window closed" or time runs out.
' The operator clicks on the panel; this script only watches.
On Error Resume Next
Dim lv, vi, fso, logf, mins, t0, last, cur, st, enumOk, k, n
Set fso = CreateObject("Scripting.FileSystemObject")
Set logf = fso.CreateTextFile(WScript.Arguments(1), True)
mins = 30 : If WScript.Arguments.Count > 2 Then mins = CDbl(WScript.Arguments(2))
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(CStr(WScript.Arguments(0)), "", False, 0)
If Err.Number <> 0 Then logf.WriteLine "OPEN FAILED: " & Err.Description : WScript.Quit 1
vi.FPWinOpen = True
vi.Run True
If Err.Number <> 0 Then logf.WriteLine "RUN FAILED: " & Err.Description : WScript.Quit 2
logf.WriteLine Now & "  started (panel open). Columns: t[s] | Status | SOC | V | I | T | Elapsed | PS | Load | Fault | FaultMsg"
t0 = Timer : last = ""
Do
  Err.Clear
  st = vi.GetControlValue("Status Message")
  cur = st & " | SOC=" & FormatNumber(vi.GetControlValue("SOC (%)"), 2) & " | V=" & FormatNumber(vi.GetControlValue("DC Voltage (V)"), 2) _
      & " | I=" & FormatNumber(vi.GetControlValue("DC Current (A)"), 2) & " | T=" & FormatNumber(vi.GetControlValue("Temperature (degC)"), 2) _
      & " | El=" & FormatNumber(vi.GetControlValue("Elapsed Time (s)"), 1) & " | PS=" & vi.GetControlValue("Sim Power Supply Output") _
      & " | Load=" & vi.GetControlValue("Sim DC Load Output") & " | Fault=" & vi.GetControlValue("Fault") & " | " & vi.GetControlValue("Fault Message")
  If Err.Number <> 0 Then cur = "READ ERROR " & Err.Number & " " & Err.Description
  ' log when anything but the slowly changing numbers changed, or every 5 s
  k = Split(cur, " | SOC=")(0) & Split(cur, " | El=")(1)
  n = n + 1
  If k <> last Or n Mod 20 = 0 Then
    logf.WriteLine FormatNumber(Timer - t0, 1) & " | " & cur
    logf.Close : Set logf = fso.OpenTextFile(WScript.Arguments(1), 8)   ' flush so the log can be read live
    last = k
  End If
  If InStr(st, "Closing") = 1 Or InStr(st, "Window closed") = 1 Then
    WScript.Sleep 1500
    logf.WriteLine FormatNumber(Timer - t0, 1) & " | FINAL | " & cur
    logf.WriteLine "VI stopped by Close (monitor ends)."
    Exit Do
  End If
  If (Timer - t0) > mins * 60 Then logf.WriteLine "monitor time limit reached - VI left running" : Exit Do
  WScript.Sleep 250
Loop
logf.Close
