param([string]$Flutter = 'flutter')
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & $Flutter test --no-pub tool/export_branding.dart --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw 'Brand export failed.' }

    # iOS app icons must have no alpha channel, even when every pixel is opaque.
    # Convert only their encoding to RGB; the generated artwork stays unchanged.
    Add-Type -AssemblyName System.Drawing
    $iconDirectory = Join-Path (Get-Location) 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    foreach ($iconFile in Get-ChildItem -LiteralPath $iconDirectory -Filter '*.png') {
        $iconBytes = [System.IO.File]::ReadAllBytes($iconFile.FullName)
        $iconStream = [System.IO.MemoryStream]::new($iconBytes, $false)
        $iconSource = [System.Drawing.Image]::FromStream($iconStream)
        $rgbIcon = [System.Drawing.Bitmap]::new($iconSource.Width, $iconSource.Height,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $iconGraphics = [System.Drawing.Graphics]::FromImage($rgbIcon)
        try {
            $iconGraphics.DrawImageUnscaled($iconSource, 0, 0)
            $rgbIcon.Save($iconFile.FullName, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $iconGraphics.Dispose()
            $rgbIcon.Dispose()
            $iconSource.Dispose()
            $iconStream.Dispose()
        }
    }
    Write-Output 'Branding exported; iOS app icons encoded as RGB without alpha.'
} finally {
    Pop-Location
}
