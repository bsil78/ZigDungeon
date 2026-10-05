$raylibPath = Join-Path $PSScriptRoot "raylib"
$patchPath = Join-Path $PSScriptRoot "raylib-no-emsdk.patch"

if (-not (Test-Path -LiteralPath $raylibPath -PathType Container)) {
    throw "Raylib source checkout not found at '$raylibPath'."
}
if (-not (Test-Path -LiteralPath $patchPath -PathType Leaf)) {
    throw "Raylib patch file not found at '$patchPath'."
}

& git -C $raylibPath rev-parse --show-toplevel *> $null
if ($LASTEXITCODE -ne 0) {
    throw "The Raylib directory is not a Git checkout."
}

function Invoke-RaylibPatch {
    param([Parameter(Mandatory = $true)][string]$File)

    $include = "--include=$File"
    $checkOutput = & git -C $raylibPath apply --check $include $patchPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        & git -C $raylibPath apply $include $patchPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to apply the Raylib patch to '$File'."
        }
        Write-Host "Patched Raylib/$File."
        return
    }

    $reverseOutput = & git -C $raylibPath apply --reverse --check $include $patchPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Raylib/$File is already patched."
        return
    }

    throw "Cannot apply the Raylib patch to '$File'. Verify the Raylib version and local changes.`n$checkOutput`n$reverseOutput"
}

Invoke-RaylibPatch "build.zig"
Invoke-RaylibPatch "build.zig.zon"
