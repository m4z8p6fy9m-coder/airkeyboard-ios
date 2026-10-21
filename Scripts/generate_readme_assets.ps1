# Optional README placeholder regeneration on Windows; only built-in .NET drawing APIs.
param([string]$Assets = (Join-Path $PSScriptRoot '../assets'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $Assets | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../App/Assets.xcassets/AppIcon.appiconset/icon.png') -Destination (Join-Path $Assets 'logo.png') -Force
function Write-Placeholder([string]$File, [string]$Title, [string]$Subtitle, [bool]$Gif) {
    $bitmap = New-Object System.Drawing.Bitmap(1200, 600)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#101B25'))
    $mint = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#83E6CA'))
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#ECF3F6'))
    $muted = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#A2B5C2'))
    $border = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#314756'), 2)
    $labelFont = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $titleFont = New-Object System.Drawing.Font('Segoe UI', 44, [System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Object System.Drawing.Font('Segoe UI', 22)
    $smallFont = New-Object System.Drawing.Font('Segoe UI', 16)
    $graphics.DrawRectangle($border, 24, 24, 1151, 551)
    $graphics.FillRectangle($mint, 64, 72, 5, 34)
    $graphics.DrawString('AIRKEYBOARD / MEDIA PLACEHOLDER', $labelFont, $mint, 88, 76)
    $graphics.DrawString($Title, $titleFont, $white, 64, 194)
    $graphics.DrawString($Subtitle, $bodyFont, $muted, 68, 286)
    $graphics.DrawLine($border, 68, 408, 1130, 408)
    $graphics.DrawString('Not a product screenshot or demo recording.', $smallFont, $muted, 68, 444)
    $graphics.DrawString('Simulator Foundation / MIT', $smallFont, $mint, 68, 486)
    $format = if ($Gif) { [System.Drawing.Imaging.ImageFormat]::Gif } else { [System.Drawing.Imaging.ImageFormat]::Png }
    $bitmap.Save((Join-Path $Assets $File), $format)
    foreach ($resource in @($labelFont,$titleFont,$bodyFont,$smallFont,$mint,$white,$muted,$border,$graphics,$bitmap)) { $resource.Dispose() }
}
Write-Placeholder 'demo.gif' 'Demo walkthrough' 'Authentic Simulator recording coming soon.' $true
Write-Placeholder 'theme-studio.png' 'Theme Studio' 'Authentic editor screenshot coming soon.' $false
Write-Output "README placeholders generated in $Assets"
