# Creates Sim_Data.ctl and Sim_Log_Record.ctl IN PLACE in Build\Simulation, with LabVIEW 2019 itself.
# Precondition: the user's Sim_Data.ctl editor window is closed (no unsaved copy in LabVIEW memory).
# The user's partial Sim_Data.ctl is backed up first (never deleted).
$ErrorActionPreference = 'Stop'
$t   = $PSScriptRoot
$sim = Join-Path (Split-Path $t -Parent) 'Simulation'
$cs  = 'C:\Windows\SysWOW64\cscript.exe'

if (Test-Path "$sim\Sim_Data.ctl") {
    $bk = "$t\staging\user_partial_Sim_Data_$(Get-Date -Format yyyyMMdd_HHmmss).ctl"
    Move-Item "$sim\Sim_Data.ctl" $bk
    "Backed up existing Sim_Data.ctl -> $bk"
}
if (Test-Path "$sim\Sim_Log_Record.ctl") { throw "Sim_Log_Record.ctl already exists - not overwriting" }

& $cs //nologo "$t\make_typedef.vbs" "$t\carriers\carrier_Sim_Data.vi" "$sim\Sim_Data.ctl"
& $cs //nologo "$t\bind_typedef.vbs" "$sim\Sim_Data.ctl" "0" 7 "$sim\Test_State_Enum2.ctl"
& $cs //nologo "$t\make_typedef.vbs" "$t\carriers\carrier_Sim_Log_Record.vi" "$sim\Sim_Log_Record.ctl"
& $cs //nologo "$t\bind_typedef.vbs" "$sim\Sim_Log_Record.ctl" "0" 1 "$sim\Sim_State_Enum.ctl"
& $cs //nologo "$t\bind_typedef.vbs" "$sim\Sim_Log_Record.ctl" "0" 2 "$sim\Sim_Data.ctl"
"Done."
