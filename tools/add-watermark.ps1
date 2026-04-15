# ANIGIFT ウォーターマーク追加スクリプト
# 使い方: .\add-watermark.ps1 -Input "動画.mp4" -Watermark "watermark.png"
# または: .\add-watermark.ps1 -InputDir "フォルダパス" -Watermark "watermark.png"

param(
    [string]$Input,
    [string]$InputDir,
    [string]$Watermark = ".\watermark.png",
    [string]$OutputDir = ".\preview"
)

# 出力フォルダ作成
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Add-Watermark {
    param([string]$VideoPath, [string]$WatermarkPath, [string]$OutDir)
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($VideoPath)
    $outPath = Join-Path $OutDir "${fileName}_preview.mp4"
    
    Write-Host "Processing: $fileName" -ForegroundColor Cyan
    
    ffmpeg -y -i $VideoPath -i $WatermarkPath `
        -filter_complex "overlay=(W-w)/2:(H-h)/2" `
        -c:v libx264 -crf 23 -preset fast `
        -c:a copy `
        $outPath 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Done: $outPath" -ForegroundColor Green
    } else {
        Write-Host "  Error: $fileName" -ForegroundColor Red
    }
}

if ($Input) {
    Add-Watermark -VideoPath $Input -WatermarkPath $Watermark -OutDir $OutputDir
} elseif ($InputDir) {
    $videos = Get-ChildItem -Path $InputDir -Include *.mp4,*.mov,*.webm -File
    foreach ($v in $videos) {
        Add-Watermark -VideoPath $v.FullName -WatermarkPath $Watermark -OutDir $OutputDir
    }
} else {
    Write-Host "使い方:" -ForegroundColor Yellow
    Write-Host "  1本: .\add-watermark.ps1 -Input '動画.mp4'" -ForegroundColor White
    Write-Host "  一括: .\add-watermark.ps1 -InputDir 'フォルダ'" -ForegroundColor White
    Write-Host ""
    Write-Host "オプション:" -ForegroundColor Yellow
    Write-Host "  -Watermark  透かしPNG (デフォルト: .\watermark.png)" -ForegroundColor White
    Write-Host "  -OutputDir  出力先 (デフォルト: .\preview)" -ForegroundColor White
}
