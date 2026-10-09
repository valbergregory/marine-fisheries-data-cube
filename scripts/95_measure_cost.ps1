# 95_measure_cost.ps1 -----------------------------------------------------
# Executa scripts/95_measure_cost.R e reporta o PICO DE MEMORIA do processo
# lido do proprio Windows, em vez de estimado pelo R.
#
#   powershell -File scripts/95_measure_cost.ps1 -Stage ingest
#   powershell -File scripts/95_measure_cost.ps1 -Stage analysis
#   powershell -File scripts/95_measure_cost.ps1 -Stage netio
#
# Dois detalhes que invalidariam a medicao se ignorados:
#  1. Rscript.exe e apenas um lancador: ele executa R.exe como processo FILHO,
#     e todo o trabalho (e toda a memoria) esta no filho. Medir so o processo
#     devolvido por Start-Process da ~10 MB, nao o pico real.
#  2. O objeto Process devolvido por Start-Process mantem valores em cache e
#     Refresh() nao atualiza PeakWorkingSet64 de forma confiavel; por isso o
#     pico e lido do SO (Win32_Process.PeakWorkingSetSize) a cada amostra.

param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("ingest", "analysis", "netio")]
  [string]$Stage,
  [string]$RScript = "C:\Program Files\R\R-4.4.3\bin\Rscript.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$log = Join-Path $root ("outputs\logs\cost_{0}_{1}.log" -f $Stage, $stamp)
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null

Write-Output ("[{0}] iniciando etapa '{1}'" -f (Get-Date -Format "HH:mm:ss"), $Stage)

$t0 = Get-Date
$p = Start-Process -FilePath $RScript `
  -ArgumentList @("scripts/95_measure_cost.R", $Stage) `
  -RedirectStandardOutput $log `
  -RedirectStandardError ($log -replace "\.log$", ".err.log") `
  -PassThru -NoNewWindow

# Pico por PID em toda a arvore (lancador + R.exe + eventuais filhos)
$peaks = @{}
$samples = 0
while (-not $p.HasExited) {
  try {
    $all = Get-CimInstance Win32_Process -ErrorAction Stop |
      Select-Object ProcessId, ParentProcessId, Name, PeakWorkingSetSize
    $tree = New-Object System.Collections.Generic.HashSet[int]
    [void]$tree.Add([int]$p.Id)
    for ($d = 0; $d -lt 4; $d++) {
      foreach ($proc in $all) {
        if ($tree.Contains([int]$proc.ParentProcessId)) {
          [void]$tree.Add([int]$proc.ProcessId)
        }
      }
    }
    foreach ($proc in $all) {
      if ($tree.Contains([int]$proc.ProcessId)) {
        $kb = [int64]$proc.PeakWorkingSetSize
        $key = "{0}:{1}" -f $proc.ProcessId, $proc.Name
        if (-not $peaks.ContainsKey($key) -or $peaks[$key] -lt $kb) {
          $peaks[$key] = $kb
        }
      }
    }
    $samples++
  } catch { }
  Start-Sleep -Milliseconds 500
}
$elapsed = (Get-Date) - $t0

$maxKb = 0
$sumKb = 0
foreach ($k in $peaks.Keys) {
  if ($peaks[$k] -gt $maxKb) { $maxKb = $peaks[$k] }
  $sumKb += $peaks[$k]
}
$maxMb = [math]::Round($maxKb / 1024, 1)
$sumMb = [math]::Round($sumKb / 1024, 1)

Write-Output ("[fim] wall={0:N1} s | PICO (processo dominante)={1} MB | PICO (soma da arvore)={2} MB | amostras={3}" -f `
  $elapsed.TotalSeconds, $maxMb, $sumMb, $samples)
foreach ($k in ($peaks.Keys | Sort-Object { -$peaks[$_] })) {
  Write-Output ("   {0,-28} {1,8:N1} MB" -f $k, ($peaks[$k] / 1024))
}

$summary = Join-Path $root ("outputs\logs\cost_{0}_{1}.peak.json" -f $Stage, $stamp)
@{
  stage = $Stage
  wall_seconds = [math]::Round($elapsed.TotalSeconds, 1)
  peak_dominant_process_mb = $maxMb
  peak_process_tree_sum_mb = $sumMb
  per_process_peak_mb = ($peaks.GetEnumerator() |
    ForEach-Object { @{ proc = $_.Key; mb = [math]::Round($_.Value / 1024, 1) } })
  samples = $samples
  sampling_ms = 500
  source = "Win32_Process.PeakWorkingSetSize, arvore de processos"
  rscript = $RScript
} | ConvertTo-Json -Depth 4 | Out-File -FilePath $summary -Encoding utf8

Write-Output ("log: {0}" -f $log)
Write-Output ("pico: {0}" -f $summary)
