param (
    [string]$SourceDir = "..\frontend\assets\exercises",
    [string]$DestDir = "..\frontend\assets\exercises_static"
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

$gifs = Get-ChildItem -Path $SourceDir -Filter "*.gif"
$count = 0

foreach ($gif in $gifs) {
    try {
        $img = [System.Drawing.Image]::FromFile($gif.FullName)
        $dim = New-Object System.Drawing.Imaging.FrameDimension($img.FrameDimensionsList[0])
        $img.SelectActiveFrame($dim, 0)
        
        $pngName = [System.IO.Path]::GetFileNameWithoutExtension($gif.Name) + ".png"
        $pngPath = Join-Path $DestDir $pngName
        
        $img.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $img.Dispose()
        $count++
    } catch {
        Write-Error "Failed to process $($gif.Name): $_"
    }
}

Write-Host "Successfully extracted $count static PNGs."
