' Usage: cscript //nologo make_typedef.vbs <carrier.vi> <target.ctl>
' Runs lvtd_make_typedef.vi (composed for LabVIEW 2019) in LabVIEW 2019 over ActiveX.
' The carrier VI's single front-panel control is saved as a typedef .ctl.
On Error Resume Next
Dim lv, vi, helper
helper = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "lvtd_make_typedef.vi"
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(helper, "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN HELPER FAILED: " & Err.Description : WScript.Quit 1
vi.SetControlValue "carrier path", CStr(WScript.Arguments(0))
vi.SetControlValue "ctl path", CStr(WScript.Arguments(1))
vi.SetControlValue "kind", 2
vi.Run False
If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
WScript.Echo "kind after save=" & vi.GetControlValue("kind after save") & "  error status=" & vi.GetControlValue("status") & "  code=" & vi.GetControlValue("code") & "  source=" & vi.GetControlValue("source")
Set vi = Nothing
