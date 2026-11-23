' Usage: cscript //nologo panel_tree.vbs <file.vi|ctl> [index path]
' Lists the controls of a front panel (or of the container at "index path", e.g. "0") with their
' index, label, typedef flag and class, using lvai_typedef_tree.vi composed for LabVIEW 2019.
On Error Resume Next
Dim lv, vi, helper, labels, td, paths, cls, k, ip
helper = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "lvai_typedef_tree.vi"
Set lv = CreateObject("LabVIEW.Application")
Set vi = lv.GetVIReference(helper, "", False, 0)
If Err.Number <> 0 Then WScript.Echo "OPEN HELPER FAILED: " & Err.Description : WScript.Quit 1
ip = "" : If WScript.Arguments.Count > 1 Then ip = CStr(WScript.Arguments(1))
If ip = "-" Then ip = ""
vi.SetControlValue "vi path", CStr(WScript.Arguments(0))
If ip <> "" Then vi.SetControlValue "index path", ip
vi.Run False
If Err.Number <> 0 Then WScript.Echo "RUN FAILED: " & Err.Description : WScript.Quit 2
' ("is typedef" is a Boolean array, which VBScript cannot read; a non-empty typedef path says the same)
labels = vi.GetControlValue("labels")
paths = vi.GetControlValue("typedef paths") : cls = vi.GetControlValue("class names")
WScript.Echo "code=" & vi.GetControlValue("code") & " " & vi.GetControlValue("source")
Dim c, p
For k = LBound(labels) To UBound(labels)
  c = "" : p = ""
  If IsArray(cls) Then If k <= UBound(cls) Then c = cls(k)
  If IsArray(paths) Then If k <= UBound(paths) Then p = paths(k)
  WScript.Echo k & vbTab & labels(k) & vbTab & c & vbTab & p
Next
