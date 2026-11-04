# Plays the PC build in a window, with no time limit. F11 saves a rendering capture.
#   powershell -ExecutionPolicy Bypass -File tools\win\play.ps1
# Log: out\logs\play.log (plus out\logs\play-report.txt and suggested.toml when it exits)
# out\logs\profile.txt: where the game thread spent its time (sampled about 1,000 times a second).
param([string]$Game = 'crazytaxi')
. "$PSScriptRoot\common.ps1"
if (-not (Test-Path $GameExe)) { throw 'Not built yet. Run tools\win\build_pc.ps1 first.' }
Start-Log 'play.log' 'play' | Out-Null
$a = @('--config', $GameToml, '--window',
       '--report', (Join-Path $LogDir 'play-report.txt'),
       '--suggest-config', (Join-Path $LogDir 'suggested.toml'))
# The boot ROM's hand-off state, register bank 1 (see boot_test.ps1).
$a += @('--boot-sr', '0x600000F1')
# Memory card: created blank on first run, kept between runs (out\saves\<game>_vmu_A1.bin).
$a += @('--vmu', $VmuFile)
# Sampling profiler: a small speed cost (not yet measured), writes its report when the window closes (naming the
# functions reads the debug symbols, so closing can take a little longer than usual).
$a += @('--profile', (Join-Path $LogDir 'profile.txt'))
$rc = Invoke-Logged $GameExe $a 'play' '^frame'
Write-Host "Game closed (exit $rc). Logs are in out\logs."
