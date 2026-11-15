param([string]$InnoCompiler = '', [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
Push-Location $project
try {
    $manifest = Get-Content pubspec.yaml -Raw
    if ($manifest -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') { throw 'Version must use major.minor.patch+build' }
    $version = $Matches[1]; $buildNumber = $Matches[2]
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    if (-not $SkipChecks) {
        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
        flutter test
        if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
        & (Join-Path $PSScriptRoot 'test-native.ps1')
    }
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
    $release = Join-Path $project 'build\windows\x64\runner\Release'
    # Flutter emits a build-only manifest with absolute developer paths here.
    $buildOnlyManifest = Join-Path $release 'native_assets.json'
    if (Test-Path -LiteralPath $buildOnlyManifest) { Remove-Item -LiteralPath $buildOnlyManifest }
    # App-local MSVC redistributables, from the Visual Studio licensed redist folder.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vs = & $vswhere -latest -products '*' -property installationPath
    $redistRoot = Join-Path $vs 'VC\Redist\MSVC'
    $redist = Get-ChildItem -LiteralPath $redistRoot -Directory | Where-Object Name -Match '^14\.' | Sort-Object Name -Descending | Select-Object -First 1
    $crt = Get-ChildItem -LiteralPath (Join-Path $redist.FullName 'x64') -Directory -Filter 'Microsoft.VC*.CRT' | Select-Object -First 1
    if (-not $crt) { throw 'MSVC redistributables were not found' }
    Copy-Item -Path (Join-Path $crt.FullName '*.dll') -Destination $release
    Copy-Item -LiteralPath LICENSE,README.md,SECURITY.md -Destination $release
    if (-not $InnoCompiler) {
        $candidates = @((Join-Path $project '.tools\InnoSetup\ISCC.exe'), (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'), (Join-Path $env:ProgramFiles 'Inno Setup 7\ISCC.exe'))
        $InnoCompiler = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }
    if (-not $InnoCompiler) { throw 'Install Inno Setup or pass -InnoCompiler' }
    & $InnoCompiler "/DAppVersion=$version" "/DBuildNumber=$buildNumber" installer\SizeSoul.iss
    if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
    New-Item -ItemType Directory -Force dist | Out-Null
    $archive = "dist\SizeSoul-$version-windows-x64-portable.zip"
    Compress-Archive -Path "$release\*" -DestinationPath $archive -Force
    $artifacts = @("dist\SizeSoul-$version-windows-x64-setup.exe", $archive)
    $checksums = foreach ($artifact in $artifacts) { $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $artifact; '{0}  {1}' -f $hash.Hash.ToLowerInvariant(), (Split-Path -Leaf $artifact) }
    $checksums | Set-Content "dist\SizeSoul-$version-SHA256SUMS.txt" -Encoding ascii
    Write-Output "Ready: SizeSoul $version installer, portable archive and checksums in dist."
} finally { Pop-Location }
