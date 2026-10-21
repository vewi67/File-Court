#requires -Version 5.1
<#
.SYNOPSIS
    File Court: real file facts, questionable justice.
.DESCRIPTION
    Reads metadata from a file selected by the user and produces a humorous verdict.
    It never deletes, moves, renames, edits, or executes the selected file.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:CurrentItem = $null
$script:CurrentRuling = $null
$script:CurrentHash = $null

# In a normal script this is PSScriptRoot. PS2EXE exposes ScriptRoot for compiled apps.
$script:AppRoot = $null
$compiledRoot = Get-Variable -Name ScriptRoot -ErrorAction SilentlyContinue
if ($compiledRoot -and -not [string]::IsNullOrWhiteSpace([string]$compiledRoot.Value)) {
    $script:AppRoot = [string]$compiledRoot.Value
} elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $script:AppRoot = $PSScriptRoot
} else {
    $script:AppRoot = [AppDomain]::CurrentDomain.BaseDirectory
}
$script:C = @{
    Background = [System.Drawing.Color]::FromArgb(15,18,26)
    Panel = [System.Drawing.Color]::FromArgb(23,29,41)
    PanelAlt = [System.Drawing.Color]::FromArgb(31,39,53)
    Text = [System.Drawing.Color]::FromArgb(237,241,248)
    Muted = [System.Drawing.Color]::FromArgb(154,166,184)
    Accent = [System.Drawing.Color]::FromArgb(116,220,196)
    Green = [System.Drawing.Color]::FromArgb(120,222,160)
    Yellow = [System.Drawing.Color]::FromArgb(255,204,118)
    Red = [System.Drawing.Color]::FromArgb(255,127,127)
    Border = [System.Drawing.Color]::FromArgb(49,60,78)
}

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -lt 1KB) { return ('{0:N0} bytes' -f $Bytes) }
    if ($Bytes -lt 1MB) { return ('{0:N2} KiB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:N2} MiB' -f ($Bytes / 1MB)) }
    if ($Bytes -lt 1TB) { return ('{0:N2} GiB' -f ($Bytes / 1GB)) }
    return ('{0:N2} TiB' -f ($Bytes / 1TB))
}

function Test-UnderRoot {
    param([string]$Path, [string]$Root)
    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($Root)) { return $false }
    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
        if ($fullPath.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        return $fullPath.StartsWith(($fullRoot + [System.IO.Path]::DirectorySeparatorChar), [System.StringComparison]::OrdinalIgnoreCase)
    } catch { return $false }
}

function Get-CourtRuling {
    param([System.IO.FileInfo]$Item)
    $ageDays = [int][Math]::Floor(((Get-Date) - $Item.LastWriteTime).TotalDays)
    $ext = $Item.Extension.ToLowerInvariant()
    $tempExts = @('.tmp','.temp','.cache','.dmp','.old','.bak')
    $archiveExts = @('.exe','.msi','.iso','.zip','.7z','.rar','.tar','.gz')
    $tempRoot = [System.IO.Path]::GetTempPath()
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
    $isTemp = (Test-UnderRoot -Path $Item.FullName -Root $tempRoot) -or ($tempExts -contains $ext)
    $isProtected = $false
    $roots = @($env:WINDIR, $env:ProgramFiles, (Join-Path $env:SystemDrive 'Program Files (x86)'), $env:ProgramData)
    foreach ($root in $roots) {
        if (Test-UnderRoot -Path $Item.FullName -Root $root) { $isProtected = $true; break }
    }
    $isSystemAttribute = (($Item.Attributes -band [System.IO.FileAttributes]::System) -ne 0)
    $isReadOnly = (($Item.Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0)
    $isDownload = Test-UnderRoot -Path $Item.FullName -Root $downloads
    $ageText = if ($ageDays -lt 0) { 'a timestamp from the future' } elseif ($ageDays -eq 0) { 'modified today' } elseif ($ageDays -eq 1) { '1 day since its last modification' } else { "$ageDays days since its last modification" }

    if ($isProtected -or $isSystemAttribute) {
        $verdict = 'HOLD THE DELETE BUTTON'
        $priority = 'COURT ORDER: DO NOT DELETE BASED ON THIS REPORT'
        $reason = 'This file lives in a Windows/application-support area or carries the System attribute. The court is not qualified to dismantle your operating system, and neither are its interns.'
        $advice = 'Leave it alone unless you know exactly what owns it and why it is safe to remove. Consult the relevant Windows or application documentation first.'
        $tone = 'Red'
    } elseif ($isTemp -and $ageDays -ge 7) {
        $verdict = 'POTENTIAL CLUTTER'
        $priority = 'REVIEW PRIORITY: WORTH A LOOK'
        $reason = "The file is in a temporary location or has a temporary-looking extension, and it was $ageText. Suspiciously clutter-shaped, but temporary files can still matter to running software."
        $advice = 'Check which application created it and whether that application is still using it. If unsure, keep it. File Court will not delete it for you.'
        $tone = 'Yellow'
    } elseif ($isDownload -and ($archiveExts -contains $ext) -and $ageDays -ge 90) {
        $verdict = 'THE OLD DOWNLOAD IS ON TRIAL'
        $priority = 'REVIEW PRIORITY: CHECK BEFORE KEEPING'
        $reason = "This looks like an installer, disk image, or archive in Downloads, and it was $ageText. It might be an old duplicate, or it might be your only copy."
        $advice = 'If the application is installed and you have another trusted copy, you may not need this download. Confirm what it is and whether you need it before deleting anything.'
        $tone = 'Yellow'
    } elseif ($Item.Length -ge 1GB) {
        $verdict = 'STORAGE HOG ON THE WITNESS STAND'
        $priority = 'REVIEW PRIORITY: LARGE FILE'
        $reason = "The defendant occupies $(Format-FileSize -Bytes $Item.Length). The number is real; the outrage is theatrical. Large files can be videos, backups, games, projects, or important archives."
        $advice = 'Review it if you need storage space, but confirm its purpose and whether another copy exists. Size alone is not a reason to delete a file.'
        $tone = 'Yellow'
    } elseif ($ageDays -ge 365) {
        $verdict = 'OLD, NOT AUTOMATICALLY GUILTY'
        $priority = 'COURT ORDER: REVIEW CONTEXT'
        $reason = "Its last-modified date is $ageText. Age is a fact, not proof of uselessness. Old documents, photos, backups, and project files can still be valuable."
        $advice = 'Identify the file and decide whether you still need it. Back up anything important before cleanup.'
        $tone = 'Accent'
    } elseif ($isReadOnly) {
        $verdict = 'THE DEFENDANT DECLINES EDITS'
        $priority = 'COURT ORDER: PROCEED CAREFULLY'
        $reason = 'Windows marks this file as read-only. That is a real attribute, but it does not explain why the file exists or whether it is needed.'
        $advice = 'Keep it unless you recognize it and have a clear reason to remove it. A read-only flag is not evidence of guilt.'
        $tone = 'Accent'
    } else {
        $verdict = 'NOT GUILTY (FOR NOW)'
        $priority = 'COURT ORDER: NO DELETION RECOMMENDED'
        $reason = 'The available metadata gives the court no responsible reason to recommend removal. The verdict is unserious; the caution is not.'
        $advice = 'Keep it unless you know what it is and have a good reason to delete it. To free space, review your largest files first.'
        $tone = 'Green'
    }

    switch ($ext) {
        '.txt' { $joke = 'The defendant claims to be plain text. Its legal team is one notepad and a dream.' }
        '.jpg' { $joke = 'The court has not seen the picture. It has only judged the paperwork. Art remains outside its jurisdiction.' }
        '.png' { $joke = 'The transparency of this file is unknown. The transparency of its filename is under investigation.' }
        '.zip' { $joke = 'The defendant has compressed its statement. The court requests a less zipped explanation.' }
        '.exe' { $joke = 'The defendant is executable. The judge declines to press the button just to see what happens.' }
        '.pdf' { $joke = 'The defendant arrived with documents. Naturally, the court now needs more documents.' }
        '.mp4' { $joke = 'The court reviewed the file size, not the movie. Spoilers are outside its jurisdiction.' }
        '.dll' { $joke = 'The defendant claims to be a library. The court will not attempt to read it aloud.' }
        '.log' { $joke = 'This file has been keeping records. The court would like to know who authorized it to take notes.' }
        default { $joke = 'The filename is suspiciously confident for something that cannot defend itself.' }
    }
    return [pscustomobject]@{ Verdict=$verdict; Priority=$priority; Reason=$reason; Advice=$advice; Joke=$joke; Tone=$tone; AgeDays=$ageDays; AgeText=$ageText }
}

function Get-CaseReport {
    if (-not $script:CurrentItem -or -not $script:CurrentRuling) { return 'No case is currently open. Select a file first.' }
    $item = $script:CurrentItem
    $ruling = $script:CurrentRuling
    $hashText = if ($script:CurrentHash) { $script:CurrentHash } else { 'Not calculated' }
    return @"
FILE COURT - CASE REPORT
========================

VERDICT: $($ruling.Verdict)
$($ruling.Priority)

DEFENDANT
---------
Name: $($item.Name)
Full path: $($item.FullName)
Extension: $(if ($item.Extension) { $item.Extension } else { 'No extension' })
Size: $(Format-FileSize -Bytes $item.Length) ($($item.Length) bytes)
Created: $($item.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))
Last modified: $($item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
Age since modification: $($ruling.AgeText)
Attributes: $($item.Attributes)
SHA-256: $hashText

WHY THE COURT RULED THIS WAY
----------------------------
$($ruling.Reason)

RECOMMENDED ACTION
------------------
$($ruling.Advice)

COURTROOM COMMENTARY
--------------------
$($ruling.Joke)

DISCLAIMER
----------
File Court reads filesystem metadata and makes jokes. It is not an antivirus and cannot reliably decide whether a file should be deleted. It never deletes, moves, renames, edits, or executes the selected file.

Part of the Ghost Series: small, intentionally odd programs built around one simple idea taken to an absurd extreme.
"@
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'File Court'
$form.StartPosition = 'CenterScreen'
$form.Size = [System.Drawing.Size]::new(1050,780)
$form.MinimumSize = [System.Drawing.Size]::new(900,680)
$form.BackColor = $script:C.Background
$form.ForeColor = $script:C.Text
$form.Font = New-Object System.Drawing.Font('Segoe UI',9)
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'; $header.Height = 105; $header.BackColor = $script:C.Panel
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'FILE COURT  /  GHOST SERIES #0111'
$title.Font = New-Object System.Drawing.Font('Segoe UI',23,[System.Drawing.FontStyle]::Bold)
$title.ForeColor = $script:C.Accent
$title.Location = [System.Drawing.Point]::new(25,12)
$title.Size = [System.Drawing.Size]::new(800,42)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'REAL FILES. REAL FACTS. QUESTIONABLE JUSTICE.'
$subtitle.Font = New-Object System.Drawing.Font('Consolas',10,[System.Drawing.FontStyle]::Bold)
$subtitle.ForeColor = $script:C.Muted
$subtitle.Location = [System.Drawing.Point]::new(29,61)
$subtitle.Size = [System.Drawing.Size]::new(700,23)
$header.Controls.Add($subtitle)

$chooseButton = New-Object System.Windows.Forms.Button
$chooseButton.Text = 'CHOOSE DEFENDANT'
$chooseButton.Location = [System.Drawing.Point]::new(25,125)
$chooseButton.Size = [System.Drawing.Size]::new(190,42)
$chooseButton.FlatStyle = 'Flat'; $chooseButton.FlatAppearance.BorderSize = 0
$chooseButton.BackColor = $script:C.Accent
$chooseButton.ForeColor = [System.Drawing.Color]::FromArgb(12,28,30)
$chooseButton.Font = New-Object System.Drawing.Font('Segoe UI',9,[System.Drawing.FontStyle]::Bold)
$chooseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($chooseButton)

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.Location = [System.Drawing.Point]::new(230,132)
$pathBox.Size = [System.Drawing.Size]::new(770,29)
$pathBox.Anchor = 'Top,Left,Right'; $pathBox.ReadOnly = $true
$pathBox.BackColor = $script:C.Panel; $pathBox.ForeColor = $script:C.Text
$pathBox.BorderStyle = 'FixedSingle'; $pathBox.Font = New-Object System.Drawing.Font('Consolas',9)
$form.Controls.Add($pathBox)

$verdictPanel = New-Object System.Windows.Forms.Panel
$verdictPanel.Location = [System.Drawing.Point]::new(25,185)
$verdictPanel.Size = [System.Drawing.Size]::new(975,112)
$verdictPanel.Anchor = 'Top,Left,Right'; $verdictPanel.BackColor = $script:C.Panel
$form.Controls.Add($verdictPanel)

$verdictLabel = New-Object System.Windows.Forms.Label
$verdictLabel.Text = 'NO CASE OPEN'
$verdictLabel.Location = [System.Drawing.Point]::new(20,13)
$verdictLabel.Size = [System.Drawing.Size]::new(930,43)
$verdictLabel.Font = New-Object System.Drawing.Font('Segoe UI',20,[System.Drawing.FontStyle]::Bold)
$verdictLabel.ForeColor = $script:C.Muted
$verdictPanel.Controls.Add($verdictLabel)

$priorityLabel = New-Object System.Windows.Forms.Label
$priorityLabel.Text = 'Select a file to hear the court talk nonsense about real metadata.'
$priorityLabel.Location = [System.Drawing.Point]::new(22,64)
$priorityLabel.Size = [System.Drawing.Size]::new(925,25)
$priorityLabel.Font = New-Object System.Drawing.Font('Consolas',9,[System.Drawing.FontStyle]::Bold)
$priorityLabel.ForeColor = $script:C.Muted
$verdictPanel.Controls.Add($priorityLabel)

$detailsPanel = New-Object System.Windows.Forms.Panel
$detailsPanel.Location = [System.Drawing.Point]::new(25,312)
$detailsPanel.Size = [System.Drawing.Size]::new(975,124)
$detailsPanel.Anchor = 'Top,Left,Right'; $detailsPanel.BackColor = $script:C.Panel
$form.Controls.Add($detailsPanel)

$script:DetailLabels = @{}
function Add-Detail {
    param([string]$Caption,[int]$X,[int]$Y,[int]$Width,[string]$Key)
    $captionLabel = New-Object System.Windows.Forms.Label
    $captionLabel.Text = $Caption.ToUpperInvariant()
    $captionLabel.Location = [System.Drawing.Point]::new($X,$Y)
    $captionLabel.Size = [System.Drawing.Size]::new($Width,18)
    $captionLabel.Font = New-Object System.Drawing.Font('Segoe UI',8,[System.Drawing.FontStyle]::Bold)
    $captionLabel.ForeColor = $script:C.Muted
    $detailsPanel.Controls.Add($captionLabel)
    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Text = 'Awaiting evidence'
    $valueLabel.Location = [System.Drawing.Point]::new($X,($Y+21))
    $valueLabel.Size = [System.Drawing.Size]::new($Width,32)
    $valueLabel.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
    $valueLabel.ForeColor = $script:C.Text; $valueLabel.AutoEllipsis = $true
    $detailsPanel.Controls.Add($valueLabel)
    $script:DetailLabels[$Key] = $valueLabel
}
Add-Detail -Caption 'FILE SIZE (REAL)' -X 18 -Y 14 -Width 210 -Key 'Size'
Add-Detail -Caption 'FILE TYPE' -X 260 -Y 14 -Width 180 -Key 'Type'
Add-Detail -Caption 'LAST MODIFIED' -X 485 -Y 14 -Width 220 -Key 'Modified'
Add-Detail -Caption 'DAYS SINCE MODIFIED' -X 735 -Y 14 -Width 220 -Key 'Age'

$caseTitle = New-Object System.Windows.Forms.Label
$caseTitle.Text = 'THE COURT RECORD'
$caseTitle.Location = [System.Drawing.Point]::new(25,450)
$caseTitle.Size = [System.Drawing.Size]::new(400,24)
$caseTitle.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
$caseTitle.ForeColor = $script:C.Accent
$form.Controls.Add($caseTitle)

$reportBox = New-Object System.Windows.Forms.RichTextBox
$reportBox.Location = [System.Drawing.Point]::new(25,480)
$reportBox.Size = [System.Drawing.Size]::new(975,155)
$reportBox.Anchor = 'Top,Bottom,Left,Right'
$reportBox.ReadOnly = $true; $reportBox.BackColor = $script:C.Panel
$reportBox.ForeColor = $script:C.Text; $reportBox.BorderStyle = 'FixedSingle'
$reportBox.Font = New-Object System.Drawing.Font('Consolas',9)
$reportBox.DetectUrls = $false
$reportBox.Text = 'CASE FILE EMPTY' + [Environment]::NewLine + [Environment]::NewLine + 'The defendant has not entered the courtroom yet.'
$form.Controls.Add($reportBox)

$buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonPanel.Location = [System.Drawing.Point]::new(25,650)
$buttonPanel.Size = [System.Drawing.Size]::new(975,55)
$buttonPanel.Anchor = 'Bottom,Left,Right'; $buttonPanel.BackColor = $script:C.Background
$buttonPanel.WrapContents = $false; $buttonPanel.AutoScroll = $true
$form.Controls.Add($buttonPanel)

function New-ActionButton {
    param([string]$Text,[int]$Width = 165)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text; $button.Size = [System.Drawing.Size]::new($Width,39)
    $button.Margin = [System.Windows.Forms.Padding]::new(0,0,9,0)
    $button.FlatStyle = 'Flat'; $button.FlatAppearance.BorderColor = $script:C.Border
    $button.BackColor = $script:C.PanelAlt; $button.ForeColor = $script:C.Text
    $button.Font = New-Object System.Drawing.Font('Segoe UI',8,[System.Drawing.FontStyle]::Bold)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonPanel.Controls.Add($button)
    return $button
}
$hashButton = New-ActionButton -Text 'CALCULATE SHA-256' -Width 170
$copyButton = New-ActionButton -Text 'COPY CASE REPORT' -Width 155
$exportButton = New-ActionButton -Text 'EXPORT REPORT...' -Width 145
$folderButton = New-ActionButton -Text 'SHOW IN EXPLORER' -Width 155
$aboutButton = New-ActionButton -Text 'ABOUT' -Width 100
$ghostArtButton = New-ActionButton -Text 'VIEW GHOST ART' -Width 145

function Update-Report { $reportBox.Text = Get-CaseReport }

function Analyze-SelectedFile {
    param([string]$LiteralPath)
    try {
        $item = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
        if ($item.PSIsContainer) {
            [void][System.Windows.Forms.MessageBox]::Show('Folders are not defendants in this court. Please select a file.','File Court','OK','Information')
            return
        }
        $script:CurrentItem = $item
        $script:CurrentRuling = Get-CourtRuling -Item $item
        $script:CurrentHash = $null
        $pathBox.Text = $item.FullName
        $verdictLabel.Text = $script:CurrentRuling.Verdict
        $verdictLabel.ForeColor = $script:C[$script:CurrentRuling.Tone]
        $priorityLabel.Text = $script:CurrentRuling.Priority
        $priorityLabel.ForeColor = $script:C[$script:CurrentRuling.Tone]
        $script:DetailLabels['Size'].Text = Format-FileSize -Bytes $item.Length
        $script:DetailLabels['Type'].Text = if ($item.Extension) { $item.Extension.ToUpperInvariant() } else { 'NO EXTENSION' }
        $script:DetailLabels['Modified'].Text = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        $script:DetailLabels['Age'].Text = "$($script:CurrentRuling.AgeDays) days"
        Update-Report
    } catch {
        [void][System.Windows.Forms.MessageBox]::Show(('The clerk could not examine this file:' + [Environment]::NewLine + $_.Exception.Message),'File Court - Clerk Error','OK','Error')
    }
}

$chooseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select a defendant for File Court'
    $dialog.Filter = 'All files (*.*)|*.*'; $dialog.CheckFileExists = $true; $dialog.Multiselect = $false
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) { Analyze-SelectedFile -LiteralPath $dialog.FileName }
    $dialog.Dispose()
})

$hashButton.Add_Click({
    if (-not $script:CurrentItem) {
        [void][System.Windows.Forms.MessageBox]::Show('The court needs a defendant before it can calculate a fingerprint.','No case open','OK','Information')
        return
    }
    try {
        $hashButton.Enabled = $false; $hashButton.Text = 'CALCULATING...'; $form.Refresh()
        $script:CurrentHash = (Get-FileHash -LiteralPath $script:CurrentItem.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
        Update-Report
        $hashMessage = 'SHA-256 calculated successfully.' + [Environment]::NewLine + [Environment]::NewLine + $script:CurrentHash
        [void][System.Windows.Forms.MessageBox]::Show($hashMessage,'Evidence Added','OK','Information')
    } catch {
        [void][System.Windows.Forms.MessageBox]::Show(('Could not calculate SHA-256:' + [Environment]::NewLine + $_.Exception.Message),'File Court','OK','Error')
    } finally { $hashButton.Enabled = $true; $hashButton.Text = 'CALCULATE SHA-256' }
})

$copyButton.Add_Click({
    if (-not $script:CurrentItem) {
        [void][System.Windows.Forms.MessageBox]::Show('There is no case report to copy yet.','No case open','OK','Information')
        return
    }
    [System.Windows.Forms.Clipboard]::SetText((Get-CaseReport))
    [void][System.Windows.Forms.MessageBox]::Show('Case report copied. The court has entered the clipboard into evidence.','Evidence Copied','OK','Information')
})

$exportButton.Add_Click({
    if (-not $script:CurrentItem) {
        [void][System.Windows.Forms.MessageBox]::Show('Open a case before exporting a report.','No case open','OK','Information')
        return
    }
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = 'Export the court record'; $dialog.Filter = 'Text report (*.txt)|*.txt'
    $dialog.FileName = 'File-Court-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss') + '.txt'
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            Set-Content -LiteralPath $dialog.FileName -Value (Get-CaseReport) -Encoding UTF8
            [void][System.Windows.Forms.MessageBox]::Show('Report exported. Justice has been documented.','Report Saved','OK','Information')
        } catch {
            [void][System.Windows.Forms.MessageBox]::Show(('Could not save the report:' + [Environment]::NewLine + $_.Exception.Message),'File Court','OK','Error')
        }
    }
    $dialog.Dispose()
})

$folderButton.Add_Click({
    if (-not $script:CurrentItem) {
        [void][System.Windows.Forms.MessageBox]::Show('There is no defendant to locate.','No case open','OK','Information')
        return
    }
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"' + $script:CurrentItem.FullName + '"') -ErrorAction SilentlyContinue
})

$aboutButton.Add_Click({
    $msg = 'File Court' + [Environment]::NewLine +
        'Real files. Real facts. Questionable justice.' + [Environment]::NewLine + [Environment]::NewLine +
        'Ghost Series program 0111 / #4' + [Environment]::NewLine + [Environment]::NewLine +
        'This app reads metadata and makes jokes. It is not an antivirus. It never deletes, moves, edits, renames, or executes files.' +
        [Environment]::NewLine + [Environment]::NewLine + 'Built entirely in PowerShell for Windows.'
    [void][System.Windows.Forms.MessageBox]::Show($msg,'About File Court','OK','Information')
})

$ghostArtButton.Add_Click({
    $artPath = Join-Path $script:AppRoot 'assets\ghost-series-art.txt'
    $artText = $null
    if (Test-Path -LiteralPath $artPath -PathType Leaf) {
        try {
            $artText = Get-Content -LiteralPath $artPath -Raw -Encoding UTF8
        } catch {
            $artText = $null
        }
    }

    if ([string]::IsNullOrWhiteSpace($artText)) {
        $artText = @'
GHOST SERIES ART NOT FOUND

Place the official ghost artwork here:
assets\ghost-series-art.txt

When building File Court.exe, the artwork is embedded into the executable.
'@
    }

    $artForm = New-Object System.Windows.Forms.Form
    $artForm.Text = 'Ghost Series Artwork | File Court'
    $artForm.StartPosition = 'CenterParent'
    $artForm.Size = [System.Drawing.Size]::new(850, 700)
    $artForm.MinimumSize = [System.Drawing.Size]::new(600, 450)
    $artForm.BackColor = $script:C.Background
    $artForm.ForeColor = $script:C.Text
    $artForm.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $artForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

    $artHeading = New-Object System.Windows.Forms.Label
    $artHeading.Text = 'OFFICIAL GHOST SERIES ARTWORK'
    $artHeading.Dock = 'Top'
    $artHeading.Height = 38
    $artHeading.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $artHeading.Padding = [System.Windows.Forms.Padding]::new(14, 0, 0, 0)
    $artHeading.ForeColor = $script:C.Accent
    $artHeading.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $artForm.Controls.Add($artHeading)

    $artBox = New-Object System.Windows.Forms.RichTextBox
    $artBox.Dock = 'Fill'
    $artBox.ReadOnly = $true
    $artBox.WordWrap = $false
    $artBox.DetectUrls = $false
    $artBox.BackColor = [System.Drawing.Color]::FromArgb(10, 13, 18)
    $artBox.ForeColor = $script:C.Accent
    $artBox.BorderStyle = 'FixedSingle'
    $artBox.Font = New-Object System.Drawing.Font('Consolas', 8.25)
    $artBox.Text = $artText.TrimEnd()
    $artForm.Controls.Add($artBox)

    $artFooter = New-Object System.Windows.Forms.Label
    $artFooter.Text = 'Ghost Series #0111  |  assets\ghost-series-art.txt'
    $artFooter.Dock = 'Bottom'
    $artFooter.Height = 27
    $artFooter.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $artFooter.Padding = [System.Windows.Forms.Padding]::new(12, 0, 0, 0)
    $artFooter.ForeColor = $script:C.Muted
    $artForm.Controls.Add($artFooter)

    [void]$artForm.ShowDialog($form)
    $artForm.Dispose()
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
