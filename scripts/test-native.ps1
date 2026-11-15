param([string]$CMake = '')
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
Push-Location $project
try {
    if (-not $CMake) {
        $found = Get-Command cmake -ErrorAction SilentlyContinue
        if ($found) { $CMake = $found.Source }
        else {
            $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
            $vs = & $vswhere -latest -products '*' -property installationPath
            $CMake = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
        }
    }
    & $CMake -S test/native -B build/native-tests -A x64
    if ($LASTEXITCODE -ne 0) { throw 'Native test configuration failed' }
    & $CMake --build build/native-tests --config Release
    if ($LASTEXITCODE -ne 0) { throw 'Native test build failed' }
    & build/native-tests/Release/storage_guard_test.exe
    if ($LASTEXITCODE -ne 0) { throw 'Native guard tests failed' }
} finally { Pop-Location }
