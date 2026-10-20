param([string]$OutputDirectory = "$PSScriptRoot\dist")
$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'Install Microsoft .NET Framework 4.8 Developer Pack to compile the Windows companion.' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$executable = Join-Path $OutputDirectory 'AirKeyboardConnect.exe'
& $compiler /nologo /target:winexe /optimize+ /platform:anycpu "/out:$executable" /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Management.dll /reference:System.ServiceProcess.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll "$PSScriptRoot\AirKeyboardConnect.cs"
if ($LASTEXITCODE -ne 0) { throw 'Windows companion compilation failed.' }
Copy-Item -LiteralPath "$PSScriptRoot\AirKeyboardConnect.exe.config" -Destination $OutputDirectory -Force
Copy-Item -LiteralPath "$PSScriptRoot\README.md" -Destination $OutputDirectory -Force
Write-Output "Built $executable"
