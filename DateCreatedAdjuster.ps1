param (
    [string]$inputFilePath
)

# Prompt for directory if no path parameter
if (-not $inputFilePath) {
    $inputFolderPath = Read-Host "Please enter the folder path containing the files to modify"
} else {
    $inputFolderPath = (Get-Content -Path $inputFilePath).Trim()
}

if (-not $inputFolderPath) {
    Write-Host "No folder path provided. Exiting."
    exit
}

# Verify folder exists
if (-not (Test-Path $inputFolderPath) -or -not (Get-Item $inputFolderPath).PSIsContainer) {
    Write-Host "Invalid folder: ${inputFolderPath}"
    exit
}

$filePaths = Get-ChildItem -Path $inputFolderPath -File -Recurse | Select-Object -ExpandProperty FullName
$filesToUpdate = @()
$shell         = New-Object -ComObject Shell.Application

foreach ($filePath in $filePaths) {
    $fileName  = [IO.Path]::GetFileName($filePath)
    $dateTaken = $null
    $parts     = $null

    # 1) Match YYYYMMDD_HHMMSS anywhere (e.g. IMG_20250115_143000.jpg)
    if ($fileName -match '(?<!\d)(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})(?!\d)') {
        $parts = $matches[1..6]
    }
    # 2) Match YYYY-MM-DD-HH-MM-SS (stand-alone)
    elseif ($fileName -match '(?<!\d)(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})(?!\d)') {
        $parts = $matches[1..6]
    }
    # 3) Match YYYY-MM-DD hh.mm.ss (space then dots)
    elseif ($fileName -match '(?<!\d)(\d{4})-(\d{2})-(\d{2}) (\d{2})\.(\d{2})\.(\d{2})(?!\d)') {
        $parts = $matches[1..6]
    }
    # 4) Match YYYY-MM-DD (not part of longer sequence)
    elseif ($fileName -match '(?<!\d)(\d{4})-(\d{2})-(\d{2})(?![\d-])') {
        $parts = $matches[1..3]
    }
    # 5) Match YYYYMMDD (stand-alone)
    elseif ($fileName -match '(?<!\d)(\d{4})(\d{2})(\d{2})(?!\d)') {
        $parts = $matches[1..3]
    }

    if ($parts) {
        try {
            if ($parts.Count -eq 6) {
                $dateTaken = Get-Date -Year   $parts[0] `
                                       -Month  $parts[1] `
                                       -Day    $parts[2] `
                                       -Hour   $parts[3] `
                                       -Minute $parts[4] `
                                       -Second $parts[5]
            } else {
                $dateTaken = Get-Date -Year  $parts[0] `
                                       -Month $parts[1] `
                                       -Day   $parts[2]
            }
        }
        catch {
            Write-Host "Invalid date parts in ${fileName} → $($_.Exception.Message)"
            $dateTaken = $null
        }
    }

    # Fallback #1: EXIF Date Taken via Shell COM
    if (-not $dateTaken) {
        $folder   = $shell.Namespace((Split-Path $filePath))
        $fileItem = $folder.ParseName($fileName)
        $metaDate = $fileItem.ExtendedProperty("System.Photo.DateTaken")
        if ($metaDate) {
            $utc       = [datetime]$metaDate
            $dateTaken = $utc.ToLocalTime()
            Write-Host "Using metadata Date Taken for ${fileName}: ${dateTaken} (from UTC ${utc})"
        }
    }

    # Fallback #2: File’s LastWriteTime (Date Modified)
    if (-not $dateTaken) {
        $fileInfo  = Get-Item $filePath
        $dateTaken = $fileInfo.LastWriteTime
        Write-Host "Using Date Modified for ${fileName}: ${dateTaken}"
    }

    if ($dateTaken) {
        $filesToUpdate += [PSCustomObject]@{
            FileName  = $fileName
            FilePath  = $filePath
            DateTaken = $dateTaken
        }
    }
}

# Debug output
Write-Host "`nDEBUG: Found $($filesToUpdate.Count) entries.`n"
$filesToUpdate | Format-Table FileName, DateTaken -AutoSize

# Preview
if ($filesToUpdate.Count -eq 0) {
    Write-Host "No valid files to update."
    exit
}

Write-Host "`nFiles to update:`n"
foreach ($f in $filesToUpdate) {
    Write-Host ("{0} -> {1}" -f $f.FileName, $f.DateTaken)
}

$confirm = Read-Host "Proceed with updating Date Created? (Y/N)"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Operation cancelled."
    exit
}

# Apply updates using UTC-aware API
foreach ($f in $filesToUpdate) {
    try {
        [System.IO.File]::SetCreationTimeUtc($f.FilePath, $f.DateTaken.ToUniversalTime())
        Write-Host ("Updated Date Created for {0} to {1}" -f $f.FileName, $f.DateTaken)
    }
    catch {
        Write-Host ("Failed to update {0}: {1}" -f $f.FileName, $_.Exception.Message)
    }
}
