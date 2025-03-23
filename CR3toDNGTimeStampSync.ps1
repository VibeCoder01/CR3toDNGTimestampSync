# Load required assemblies for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sync DNG and CR3 Timestamps"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"

# DNG Folder controls
$lblDNG = New-Object System.Windows.Forms.Label
$lblDNG.Location = New-Object System.Drawing.Point(10,20)
$lblDNG.Size = New-Object System.Drawing.Size(80,20)
$lblDNG.Text = "DNG Folder:"
$form.Controls.Add($lblDNG)

$txtDNG = New-Object System.Windows.Forms.TextBox
$txtDNG.Location = New-Object System.Drawing.Point(100,20)
$txtDNG.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($txtDNG)

$btnDNG = New-Object System.Windows.Forms.Button
$btnDNG.Location = New-Object System.Drawing.Point(390,18)
$btnDNG.Size = New-Object System.Drawing.Size(75,23)
$btnDNG.Text = "Browse..."
$btnDNG.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if($folderBrowser.ShowDialog() -eq "OK"){
        $txtDNG.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($btnDNG)

# CR3 Folder controls
$lblCR3 = New-Object System.Windows.Forms.Label
$lblCR3.Location = New-Object System.Drawing.Point(10,60)
$lblCR3.Size = New-Object System.Drawing.Size(80,20)
$lblCR3.Text = "CR3 Folder:"
$form.Controls.Add($lblCR3)

$txtCR3 = New-Object System.Windows.Forms.TextBox
$txtCR3.Location = New-Object System.Drawing.Point(100,60)
$txtCR3.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($txtCR3)

$btnCR3 = New-Object System.Windows.Forms.Button
$btnCR3.Location = New-Object System.Drawing.Point(390,58)
$btnCR3.Size = New-Object System.Drawing.Size(75,23)
$btnCR3.Text = "Browse..."
$btnCR3.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if($folderBrowser.ShowDialog() -eq "OK"){
        $txtCR3.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($btnCR3)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,120)
$progressBar.Size = New-Object System.Drawing.Size(460,23)
$progressBar.Minimum = 0
$progressBar.Step = 1
$form.Controls.Add($progressBar)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10,150)
$statusLabel.Size = New-Object System.Drawing.Size(460,20)
$statusLabel.Text = "Status: Waiting to start..."
$form.Controls.Add($statusLabel)

# Start button
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(200,190)
$btnStart.Size = New-Object System.Drawing.Size(75,30)
$btnStart.Text = "Start"
$btnStart.Add_Click({
    # Validate folder paths
    if (-not (Test-Path $txtDNG.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid DNG folder.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    if (-not (Test-Path $txtCR3.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid CR3 folder.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    # Get all .DNG files in the DNG folder
    $dngFiles = Get-ChildItem -Path $txtDNG.Text -Filter *.DNG -File
    if($dngFiles.Count -eq 0){
        [System.Windows.Forms.MessageBox]::Show("No .DNG files found in the selected folder.","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    # Initialize progress bar
    $progressBar.Minimum = 0
    $progressBar.Maximum = $dngFiles.Count
    $progressBar.Value = 0

    $statusLabel.Text = "Status: Processing files..."
    
    foreach ($dng in $dngFiles) {
        # Get the base name without extension
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($dng.Name)
        # Construct corresponding CR3 file path
        $cr3Path = Join-Path -Path $txtCR3.Text -ChildPath ($baseName + ".CR3")
        
        if(Test-Path $cr3Path) {
            try {
                # Get the timestamp from the CR3 file (using LastWriteTime)
                $timestamp = (Get-Item $cr3Path).LastWriteTime
                # Update the DNG file's creation and last write time
                [System.IO.File]::SetCreationTime($dng.FullName, $timestamp)
                [System.IO.File]::SetLastWriteTime($dng.FullName, $timestamp)
            }
            catch {
                Write-Host "Error processing $($dng.FullName): $_"
            }
        }
        else {
            Write-Host "No matching CR3 file for $($dng.Name)"
        }
        
        # Update progress bar and status
        $progressBar.PerformStep()
        $statusLabel.Text = "Processed $($progressBar.Value) of $($progressBar.Maximum) files..."
        # Refresh the form to update UI
        $form.Refresh()
    }
    
    $statusLabel.Text = "Status: Done."
    [System.Windows.Forms.MessageBox]::Show("Timestamp sync complete!","Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($btnStart)

# Show the form
[void] $form.ShowDialog()
