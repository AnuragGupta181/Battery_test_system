' Usage: cscript //nologo bind_typedef.vbs <target.ctl|vi> <index path> <child index> <source.ctl>
' Runs lvai_typedef_bind.vi (composed for LabVIEW 2019): replaces one control (e.g. a cluster
' element) with an instance of <source.ctl>, then saves the target in place.
' index path: pipe-separated indices of the CONTAINER ("0" = first panel control, e.g. the cluster);
'             "-" = the front panel itself (to replace a top-level control of a VI).
On Error Resume Next
Dim lv, vi, helper
helper = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "lvai_typedef_bind.vi"
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(helper, "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN HELPER FAILED: " & Err.Description : WScript.Quit 1
vi.SetControlValue "vi path", CStr(WScript.Arguments(0))
Dim ip : ip = CStr(WScript.Arguments(1))
If ip = "-" Then ip = ""   ' "-" = the front panel itself (PowerShell 5.1 drops empty arguments)
vi.SetControlValue "index path", ip
vi.SetControlValue "child index", CLng(WScript.Arguments(2))
vi.SetControlValue "source ctl path", CStr(WScript.Arguments(3))
vi.Run False
If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
WScript.Echo "code=" & vi.GetControlValue("code") & "  source=" & vi.GetControlValue("source")
Set vi = Nothing
