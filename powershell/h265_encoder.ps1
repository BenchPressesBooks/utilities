# Define the directory to search
$sourceDirectory = "C:\Folder\To\Convert\Here"
$workingFileName = "_fileprocessing.mp4"

# Define the ffmpeg path
$ffmpegPath = "C:\Path\To\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe"

# Function to convert video to H.265 using ffmpeg
function ConvertToH265($videoFile) {
    $inputFile = $videoFile.FullName
    $outputFile = $videoFile.FullName.Replace($videoFile.Extension, $workingFileName)
    & $ffmpegPath -i $inputFile -c:v libx265 -crf 28 -c:a aac -b:a 128k $outputFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Converted $inputFile to H.265 format." -ForegroundColor Green
        Remove-Item $inputFile
        return $outputFile
    } else {
        Write-Host "Failed to convert $inputFile." -ForegroundColor Red
        return $null
    }
}

# Function to check if a file is encoded in H.265 format
function IsH265($videoFile) {
    $output = & $ffmpegPath -i $videoFile 2>&1 | Select-String -Pattern "hevc"
    return $output -ne $null
}

# Function to check if a file has a video extension
function IsVideoExtension($file) {
    $videoExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm", ".ts", ".m4v")
    return $videoExtensions -contains $file.Extension.ToLower()
}

# Recursive function to search for video files and convert them
function ProcessDirectory($directory) {
    $files = Get-ChildItem $directory -File
    foreach ($file in $files) {

        if (IsVideoExtension $file) {
            Write-Host "$($file.FullName) is a supported video format." -ForegroundColor White

            if (IsH265 $file.FullName) {
                Write-Host "$($file.FullName) is an H265 encoded MP4. SKIPPING." -ForegroundColor Yellow
            } else {
                Write-Host "$($file.FullName) is a $($file.Extension) and is NOT h265 encoded at this time. Beginning conversion..." -ForegroundColor Cyan
                Start-Sleep -Seconds 2

                $convertedFile = ConvertToH265 $file

                if ($convertedFile) {
                    Rename-Item $convertedFile $file.Name

                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Renamed $(Split-Path -Path $convertedFile -Leaf) back to $($file.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "Rename of $(Split-Path -Path $convertedFile -Leaf) failed. This must now be done manually." -ForegroundColor Red
                    }
                }
            }
        } else {
            Write-Host "$($file.FullName) is not a video. SKIPPING." -ForegroundColor Magenta
        }
    }

    $subDirectories = Get-ChildItem $directory -Directory
    foreach ($subDirectory in $subDirectories) {
        ProcessDirectory $subDirectory.FullName
    }
}

# Cleanup orphaned files from a previous failed run
Write-Host "Beginning check for orphaned files..." -ForegroundColor White
Start-Sleep -Seconds 2
Get-ChildItem -Path $sourceDirectory -Recurse -File -Filter "*$($workingFileName)" | ForEach-Object {
    Remove-Item $_.FullName -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Cleaned up file orphan from prior run: $($_.FullName)" -ForegroundColor Yellow
    } else {
        Write-Host "Failed to remove file orphan from prior run: $($_.FullName)"  -ForegroundColor Red
        Write-Host "This is a fatal error. Manually remove this file and rerun the program."  -ForegroundColor DarkRed
    }
}
Write-Host "Orphaned file cleanup complete." -ForegroundColor White
Write-Host "*************************************************************************************************************" -ForegroundColor White
Write-Host
Write-Host
Write-Host

# Start processing the directory
Write-Host "Beginning video conversion stage..." -ForegroundColor White
Start-Sleep -Seconds 2
ProcessDirectory $sourceDirectory
