' Usage: cscript //nologo panel_png.vbs <file.vi> <out.png>
' Saves the VI's whole front panel as PNG, using lv_panel_png.vi composed for LabVIEW 2019.
On Error Resume Next
Dim lv, vi, helper
helper = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "lv_panel_png.vi"
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(helper, "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN HELPER FAILED: " & Err.Description : WScript.Quit 1
vi.SetControlValue "vi path", CStr(WScript.Arguments(0))
vi.SetControlValue "png path", CStr(WScript.Arguments(1))
vi.Run False
If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
WScript.Echo "code=" & vi.GetControlValue("code") & " " & vi.GetControlValue("source")
