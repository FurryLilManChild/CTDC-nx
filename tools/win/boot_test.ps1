# Boots the game for up to 120 GAME seconds in a window, then closes it. Game time runs slower
# than real time while code still goes through the interpreter. Writes:
#   out\logs\boot.log          everything the launcher printed
#   out\logs\boot-report.txt   where the run got to and why it stopped
#   out\logs\suggested.toml    code the run reached that is not translated yet (Claude merges it)
#   powershell -ExecutionPolicy Bypass -File tools\win\boot_test.ps1 [-Seconds 120] [-Headless] [-Game crazytaxi2]
param([int]$Seconds = 120, [switch]$Headless, [string]$Game = 'crazytaxi')
. "$PSScriptRoot\common.ps1"
if (-not (Test-Path $GameExe)) { throw 'Not built yet. Run tools\win\build_pc.ps1 first.' }
Start-Log 'boot.log' "boot_test $GameId $Seconds s" | Out-Null

$a = @('--config', $GameToml, '--max-seconds', $Seconds,
       '--report', (Join-Path $LogDir 'boot-report.txt'),
       '--suggest-config', (Join-Path $LogDir 'suggested.toml'))
# Start on CPU register bank 1 (SR.RB = 1), the state SA-nx needed (taken from a captured real
# boot). Expected to be the boot ROM's hand-off for every game, so Crazy Taxi starts the same way.
# Not yet confirmed for Crazy Taxi: if a boot misbehaves, a run without it is a cheap check.
$a += @('--boot-sr', '0x600000F1')
# Memory card: created blank on first run, kept between runs (out\saves\<game>_vmu_A1.bin).
$a += @('--vmu', $VmuFile)
if (-not $Headless) { $a += '--window' }
Write-Host "Booting $GameId for up to $Seconds game seconds (more in real time while it runs slow) ..."
$rc = Invoke-Logged $GameExe $a 'boot' '^frame'
Write-Host "Finished (exit $rc). Tell Claude the boot test is done; logs are in out\logs."
