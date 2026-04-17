# ANIGIFT Edge Fade Tool
# Adds transparent gradient edges + fade in/out to videos, outputs as WebM (VP9 alpha)

param(
    [ValidateSet("vertical", "horizontal", "all", "none")]
    [string]$Direction = "vertical",

    [ValidateRange(1, 30)]
    [int]$FadePercent = 8,

    [double]$FadeInSec = 0,
    [double]$FadeOutSec = 0,

    [string]$InputDir = (Join-Path $PSScriptRoot "input"),
    [string]$OutputDir = (Join-Path $PSScriptRoot "output")
)

# --- Setup ---
if (!(Test-Path $InputDir)) {
    Write-Host "ERROR: input folder not found: $InputDir" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force $OutputDir | Out-Null
}

$videos = Get-ChildItem $InputDir -File -Include "*.mp4","*.mov","*.avi","*.mkv" -Recurse
if ($videos.Count -eq 0) {
    Write-Host "ERROR: No video files found in input folder" -ForegroundColor Red
    exit 1
}

# --- Display settings ---
$fadeInLabel = if ($FadeInSec -gt 0) { "${FadeInSec}s" } else { "OFF" }
$fadeOutLabel = if ($FadeOutSec -gt 0) { "${FadeOutSec}s" } else { "OFF" }
$edgeLabel = if ($Direction -eq "none") { "OFF" } else { "$Direction ($FadePercent%)" }

Write-Host ""
Write-Host "=== ANIGIFT Edge Fade Tool ===" -ForegroundColor Magenta
Write-Host "  Edge Fade  : $edgeLabel"
Write-Host "  Fade In    : $fadeInLabel"
Write-Host "  Fade Out   : $fadeOutLabel"
Write-Host "  Files      : $($videos.Count)"
Write-Host "===============================" -ForegroundColor Magenta
Write-Host ""

# --- Build alpha expression for edge fade ---
$f = $FadePercent / 100.0

$alphaTop    = "if(lt(Y,H*$f),255*Y/(H*$f),255)"
$alphaBottom = "if(gt(Y,H*(1-$f)),255*(H-Y)/(H*$f),255)"
$alphaLeft   = "if(lt(X,W*$f),255*X/(W*$f),255)"
$alphaRight  = "if(gt(X,W*(1-$f)),255*(W-X)/(W*$f),255)"

switch ($Direction) {
    "vertical"   { $alphaExpr = "min($alphaTop,$alphaBottom)" }
    "horizontal" { $alphaExpr = "min($alphaLeft,$alphaRight)" }
    "all"        { $alphaExpr = "min(min($alphaTop,$alphaBottom),min($alphaLeft,$alphaRight))" }
    "none"       { $alphaExpr = "" }
}

# --- Helper: get video duration via ffprobe ---
function Get-VideoDuration($filePath) {
    $result = & ffprobe -v quiet -show_entries format=duration -of csv=p=0 $filePath 2>$null
    if ($result) { return [double]$result } else { return 0 }
}

# --- Process each video ---
$successCount = 0
$failCount = 0
$total = $videos.Count

foreach ($video in $videos) {
    $idx = $successCount + $failCount + 1
    $outName = "$($video.BaseName).webm"
    $outputFile = Join-Path $OutputDir $outName

    Write-Host "[$idx/$total] $($video.Name) -> $outName" -ForegroundColor Cyan

    # Build filter chain
    $filters = @()
    $filters += "format=rgba"

    # Edge fade (geq)
    if ($alphaExpr -ne "") {
        $filters += "geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='$alphaExpr'"
    }

    # Fade in (alpha only)
    if ($FadeInSec -gt 0) {
        $filters += "fade=t=in:st=0:d=${FadeInSec}:alpha=1"
    }

    # Fade out (alpha only, need duration)
    if ($FadeOutSec -gt 0) {
        $duration = Get-VideoDuration $video.FullName
        if ($duration -gt 0) {
            $fadeOutStart = [math]::Round($duration - $FadeOutSec, 3)
            if ($fadeOutStart -lt 0) { $fadeOutStart = 0 }
            $filters += "fade=t=out:st=${fadeOutStart}:d=${FadeOutSec}:alpha=1"
        }
    }

    $filterStr = $filters -join ","
    $errLog = Join-Path $env:TEMP "ffmpeg_edge_fade_err.txt"

    $proc = Start-Process -FilePath "ffmpeg" -ArgumentList @(
        "-i", "`"$($video.FullName)`"",
        "-filter_complex", "`"$filterStr`"",
        "-c:v", "libvpx-vp9",
        "-pix_fmt", "yuva420p",
        "-b:v", "2M",
        "-c:a", "libopus",
        "-y",
        "`"$outputFile`""
    ) -NoNewWindow -Wait -PassThru -RedirectStandardError $errLog

    if ($proc.ExitCode -eq 0) {
        $inMB  = [math]::Round($video.Length / 1MB, 2)
        $outMB = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
        Write-Host "  OK ($inMB MB -> $outMB MB)" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  FAILED" -ForegroundColor Red
        if (Test-Path $errLog) {
            $tail = Get-Content $errLog -Tail 3
            foreach ($line in $tail) {
                Write-Host "    $line" -ForegroundColor DarkRed
            }
        }
        $failCount++
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Magenta
Write-Host "  Success: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed : $failCount" -ForegroundColor Red
}

# --- ZIP packaging ---
if ($successCount -gt 0) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "anigift_fade_$timestamp.zip"
    $zipPath = Join-Path $PSScriptRoot $zipName

    Write-Host ""
    Write-Host "Packaging ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path (Join-Path $OutputDir "*") -DestinationPath $zipPath -Force
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host "  ZIP: $zipName ($zipSize MB)" -ForegroundColor Green

    # --- Cleanup input and output ---
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    Get-ChildItem $InputDir -File | Remove-Item -Force
    Get-ChildItem $OutputDir -File | Remove-Item -Force
    Write-Host "  input/ and output/ cleared" -ForegroundColor Green
}

Write-Host ""
Write-Host "  ZIP location: $PSScriptRoot" -ForegroundColor Cyan
Write-Host ""
