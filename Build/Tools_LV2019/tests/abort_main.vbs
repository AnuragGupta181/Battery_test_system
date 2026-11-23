' Usage: cscript //nologo abort_main.vbs <main.vi>
' Aborts the VI if it is still running (e.g. after its monitor script was stopped).
On Error Resume Next
Dim lv, vi
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(CStr(WScript.Arguments(0)), "", False, 0)
vi.Abort
If Err.Number <> 0 Then WScript.Echo "abort: " & Err.Description Else WScript.Echo "aborted (or was idle)"
