$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$project = Split-Path -Parent $PSScriptRoot
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$images = @()
foreach ($size in $sizes) {
    $bitmap = New-Object Drawing.Bitmap($size, $size)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([Drawing.Color]::FromArgb(24, 26, 29))
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(240, 183, 117))
    for ($i = 0; $i -lt 3; $i++) {
        $graphics.FillRectangle($brush, [single]($size*.18), [single]($size*(.19+$i*.23)), [single]($size*(.64-$i*.16)), [single]($size*.14))
    }
    $graphics.FillEllipse($brush, [single]($size*.72), [single]($size*.65), [single]($size*.14), [single]($size*.14))
    $stream = New-Object IO.MemoryStream
    $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
    $images += ,($stream.ToArray())
    if ($size -eq 256) { $bitmap.Save((Join-Path $project 'assets\branding\sizesoul.png'), [Drawing.Imaging.ImageFormat]::Png) }
    $stream.Dispose(); $brush.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
$target = Join-Path $project 'windows\runner\resources\app_icon.ico'
$output = [IO.File]::Create($target)
$writer = New-Object IO.BinaryWriter($output)
$writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Length)
$offset = 6 + 16 * $sizes.Length
for ($i = 0; $i -lt $sizes.Length; $i++) {
    $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
    $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
    $writer.Write([byte]0); $writer.Write([byte]0)
    $writer.Write([uint16]1); $writer.Write([uint16]32)
    $writer.Write([uint32]$images[$i].Length); $writer.Write([uint32]$offset)
    $offset += $images[$i].Length
}
foreach ($data in $images) { $writer.Write([byte[]]$data) }
$writer.Dispose(); $output.Dispose()
