' Usage: cscript //nologo layout_panel.vbs <file.vi>
' Runs lv_layout_panel.vi (composed for LabVIEW 2019) on <file.vi> and saves it in place.
' Prints one error code per panel control (0 = moved/coloured fine).
On Error Resume Next
Dim lv, vi, helper, names, codes, k, n, line
helper = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "lv_layout_panel.vi"
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(helper, "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN HELPER FAILED: " & Err.Description : WScript.Quit 1
vi.SetControlValue "vi path", CStr(WScript.Arguments(0))
vi.Run False
If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
WScript.Echo "final code=" & vi.GetControlValue("code") & " " & vi.GetControlValue("source")
WScript.Echo "label | table index (-1 = not in table) | read error | write error" & vbCrLf & vi.GetControlValue("report")
WScript.Quit 0
names = vi.GetControlValue("Names")
codes = vi.GetControlValue("Codes")
' LabVIEW returns typed SAFEARRAYs: indexing them in VBScript gives "Type mismatch", For Each works.
Dim a(), b(), x : n = 0
ReDim a(UBound(names)) : ReDim b(UBound(codes))
For Each x In names : a(n) = CStr(x) : n = n + 1 : Next
n = 0
For Each x In codes : b(n) = CLng(x) : n = n + 1 : Next
WScript.Echo "controls seen: " & (UBound(a) + 1)
For k = 0 To UBound(a)
  WScript.Echo CStr(k) & vbTab & b(k) & vbTab & a(k)
Next
