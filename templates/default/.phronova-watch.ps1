param([string]$ProjectPath)

$files = @()

$main = Join-Path $ProjectPath "main.lua"
if (Test-Path -LiteralPath $main) {
    $files += Get-Item -LiteralPath $main
}

$src = Join-Path $ProjectPath "src"
if (Test-Path -LiteralPath $src) {
    $files += Get-ChildItem -LiteralPath $src -Recurse -File
}

$files |
    Sort-Object FullName |
    ForEach-Object {
        "$($_.FullName)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)"
    }
