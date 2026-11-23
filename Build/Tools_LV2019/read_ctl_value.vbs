' Usage: cscript //nologo read_ctl_value.vbs <file.ctl|vi> <control label>
' Prints a control's saved (default) value; clusters come back as arrays of elements.
On Error Resume Next
Dim lv, vi, v, k, s
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(CStr(WScript.Arguments(0)), "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN FAILED: " & Err.Description : WScript.Quit 1
v = vi.GetControlValue(CStr(WScript.Arguments(1)))
If Err.Number <> 0 Then WScript.Echo "READ FAILED: " & Err.Description : WScript.Quit 2
If IsArray(v) Then
  s = ""
  For k = LBound(v) To UBound(v)
    s = s & "[" & k & "]=" & v(k) & "  "
  Next
  WScript.Echo s
Else
  WScript.Echo v
End If
Set vi = Nothing
