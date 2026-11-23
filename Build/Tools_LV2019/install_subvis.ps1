# Copies the tested staging subVIs into Build\Simulation (never overwrites) and binds their typedef
# controls IN PLACE with LabVIEW 2019. Binds go from the highest panel index down, so a Replace that
# re-orders the panel cannot shift an index that is still to be bound.
$ErrorActionPreference = 'Stop'
$t   = $PSScriptRoot
$sim = Join-Path (Split-Path $t -Parent) 'Simulation'
$cs  = 'C:\Windows\SysWOW64\cscript.exe'
$D = "$sim\Sim_Data.ctl"; $S = "$sim\Sim_Settings.ctl"; $E = "$sim\Sim_State_Enum.ctl"; $L = "$sim\Sim_Log_Record.ctl"

# name -> list of @(indexPath, childIndex, ctl)
$plan = [ordered]@{
  'Sim_Update_Model'     = @(@('-',4,$D), @('-',2,$E), @('-',1,$S), @('-',0,$D))
  'Sim_Check_Safety'     = @(@('-',2,$D), @('-',1,$S), @('-',0,$D))
  'Sim_Check_Completion' = @(@('-',3,$D), @('-',2,$E), @('-',1,$S), @('-',0,$D))
  'Sim_Save_CSV'         = @(,@('0',0,$L))   # leading comma keeps a one-item list nested
}
foreach ($n in $plan.Keys) {
  $dst = "$sim\$n.vi"
  if (Test-Path $dst) { "$n : EXISTS - skipped (not overwriting)"; continue }
  Copy-Item "$t\staging\$n.vi" $dst
  foreach ($b in $plan[$n]) {
    $r = & $cs //nologo "$t\bind_typedef.vbs" $dst $b[0] $b[1] $b[2]
    "$n : bind [$($b[0])/$($b[1])] -> $(Split-Path $b[2] -Leaf) : $r"
  }
}
