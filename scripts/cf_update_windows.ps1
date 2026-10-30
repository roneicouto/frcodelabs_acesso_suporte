param([Parameter(Mandatory=$true)][string]$Plan)
$ErrorActionPreference = 'Stop'
$updatePlan = $null
$backup = $null
$replaced = $false
$logPath = Join-Path (Split-Path -Parent $Plan) 'update.log'
function Write-UpdateLog([string]$Message) {
    Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) $Message" -Encoding UTF8
}
function Same-Path([string]$Left, [string]$Right) {
    return [string]::Equals([IO.Path]::GetFullPath($Left), [IO.Path]::GetFullPath($Right), [StringComparison]::OrdinalIgnoreCase)
}
function Restart-Client {
    if ($updatePlan.mode -eq 'portable' -and $updatePlan.profile -eq 'full') {
        Start-Process -FilePath $updatePlan.target -ArgumentList '--noinstall' | Out-Null
    } else {
        Start-Process -FilePath $updatePlan.target | Out-Null
    }
}
try {
    $updatePlan = Get-Content -LiteralPath $Plan -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($updatePlan.mode -notin @('portable', 'installed') -or $updatePlan.profile -notin @('full', 'qs') -or
        $updatePlan.sha256 -notmatch '^[a-f0-9]{64}$' -or $updatePlan.version -notmatch '^\d+\.\d+\.\d+$') {
        throw 'Invalid update plan'
    }
    foreach ($item in @($updatePlan.package, $updatePlan.target, $updatePlan.runtime)) {
        if (-not [IO.Path]::IsPathRooted($item) -or -not (Test-Path -LiteralPath $item -PathType Leaf)) {
            throw 'Update path is unavailable'
        }
    }
    if ((Same-Path $updatePlan.package $updatePlan.target) -or
        [IO.Path]::GetExtension($updatePlan.target) -ne '.exe') { throw 'Invalid update target' }
    $expectedRuntime = if ($updatePlan.profile -eq 'qs') { 'FRCodeLabsQS.exe' } else { 'FRCodeLabs.exe' }
    if ([IO.Path]::GetFileName($updatePlan.runtime) -ne $expectedRuntime) { throw 'Invalid client process' }
    if ($updatePlan.mode -eq 'installed' -and ($updatePlan.profile -ne 'full' -or
        -not (Same-Path $updatePlan.target $updatePlan.runtime))) { throw 'Invalid installed client' }
    if ($updatePlan.mode -eq 'portable' -and (Same-Path $updatePlan.target $updatePlan.runtime)) {
        throw 'The portable launcher must be outside the extracted application'
    }
    $file = Get-Item -LiteralPath $updatePlan.package
    if ($file.Length -ne $updatePlan.bytes -or
        (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -ne $updatePlan.sha256) {
        throw 'Package integrity check failed'
    }
    Write-UpdateLog "Verified $($updatePlan.profile) $($updatePlan.version), mode $($updatePlan.mode)"
    Set-Content -LiteralPath "$Plan.ready" -Value 'ready' -Encoding ASCII
    $deadline = (Get-Date).AddSeconds(45)
    while (-not (Test-Path -LiteralPath "$Plan.go")) {
        if ((Get-Date) -gt $deadline) { throw 'Update confirmation timed out' }
        Start-Sleep -Milliseconds 200
    }
    $deadline = (Get-Date).AddSeconds(90)
    while ($true) {
        $running = Get-Process -Id $updatePlan.processId -ErrorAction SilentlyContinue
        if (-not $running -or -not (Same-Path $running.Path $updatePlan.runtime)) { break }
        if ((Get-Date) -gt $deadline) { throw 'The application did not close. Close it and try again.' }
        Start-Sleep -Milliseconds 250
    }
    if ($updatePlan.mode -eq 'portable') {
        # The launcher extracts into a shared profile directory. Do not overwrite
        # DLLs used by another session or the portable elevation process.
        $deadline = (Get-Date).AddSeconds(20)
        do {
            $others = @(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($updatePlan.runtime)) -ErrorAction SilentlyContinue |
                Where-Object { $_.Path -and (Same-Path $_.Path $updatePlan.runtime) })
            if ($others.Count -eq 0) { break }
            if ((Get-Date) -gt $deadline) { throw 'Close other FR CODE LABS windows before updating.' }
            Start-Sleep -Milliseconds 500
        } while ($true)
        $backup = "$($updatePlan.target).previous"
        $incoming = "$($updatePlan.target).incoming-$([Guid]::NewGuid().ToString('N'))"
        Copy-Item -LiteralPath $updatePlan.package -Destination $incoming
        try {
            [IO.File]::Replace($incoming, $updatePlan.target, $backup, $true)
            $replaced = $true
        } finally {
            if (Test-Path -LiteralPath $incoming) { Remove-Item -LiteralPath $incoming -Force }
        }
    } else {
        # Use the upstream installer to preserve the service, install location,
        # permissions and settings. Windows presents its normal UAC prompt.
        $installer = Start-Process -FilePath $updatePlan.package -ArgumentList '--update' -Verb RunAs -PassThru
        $metadata = Join-Path (Split-Path -Parent $updatePlan.target) 'data\flutter_assets\assets\cf_legal.json'
        $deadline = (Get-Date).AddSeconds(180)
        while ($true) {
            $version = if (Test-Path -LiteralPath $metadata) {
                (Get-Content -LiteralPath $metadata -Raw -Encoding UTF8 | ConvertFrom-Json).version
            } else { '' }
            # The packer exits after spawning the native updater. Wait for that
            # direct child, not its restored tray process, which stays running.
            $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId = $($installer.Id) AND Name = 'FRCodeLabs.exe'")
            if ($version -eq $updatePlan.version -and $installer.HasExited -and $children.Count -eq 0) { break }
            if ((Get-Date) -gt $deadline) { throw 'The installer did not finish updating. Run the downloaded package again.' }
            Start-Sleep -Seconds 1
        }
    }
    Restart-Client
    Write-UpdateLog 'Update applied; application launched.'
    Set-Content -LiteralPath "$Plan.done" -Value 'done' -Encoding ASCII
} catch {
    $message = $_.Exception.Message
    Write-UpdateLog "ERROR: $message"
    Set-Content -LiteralPath "$Plan.error" -Value $message -Encoding UTF8
    if (Test-Path -LiteralPath "$Plan.go") {
        if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $backup -Destination $updatePlan.target -Force
        }
        if ($updatePlan -and (Test-Path -LiteralPath $updatePlan.target)) {
            try { Restart-Client } catch { Write-UpdateLog "Restart failed: $_" }
        }
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show("Nao foi possivel concluir a atualizacao do FR CODE LABS.`n$message`n`nDetalhes: $logPath", 'FR CODE LABS') | Out-Null
    }
    exit 1
}

