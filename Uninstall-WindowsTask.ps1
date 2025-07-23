# Augment Monitor Windows Scheduled Task Uninstallation Script
# This script removes the Augment Monitor scheduled task

param(
    [switch]$Force,
    [switch]$WhatIf
)

$TaskName = "AugmentMonitor"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    if ($WhatIf) {
        Write-ColorOutput "🔍 WHAT-IF: Would request elevation to Administrator privileges" "Magenta"
        return
    }

    Write-ColorOutput "🔐 Requesting Administrator privileges..." "Yellow"
    Write-ColorOutput "   Please click 'Yes' on the UAC prompt to continue." "Gray"

    # Get the current script path and build arguments
    $scriptPath = $PSCommandPath
    $argList = @("-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"")

    # Add original parameters
    if ($Force) { $argList += "-Force" }

    try {
        Start-Process powershell -ArgumentList $argList -Verb RunAs -Wait
        exit 0
    } catch {
        Write-ColorOutput "❌ Failed to elevate privileges: $($_.Exception.Message)" "Red"
        Write-ColorOutput "   Please run PowerShell as Administrator manually." "Yellow"
        exit 1
    }
}

function Remove-AugmentTask {
    Write-ColorOutput "🔍 Checking for existing scheduled task..." "Cyan"
    
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if (-not $existingTask) {
        Write-ColorOutput "ℹ️  No scheduled task named '$TaskName' found." "Yellow"
        return
    }
    
    Write-ColorOutput "📋 Found scheduled task:" "White"
    Write-ColorOutput "   Name: $($existingTask.TaskName)" "Gray"
    Write-ColorOutput "   State: $($existingTask.State)" "Gray"
    Write-ColorOutput "   Description: $($existingTask.Description)" "Gray"
    Write-ColorOutput "" "White"
    
    if ($WhatIf) {
        Write-ColorOutput "🔍 WHAT-IF: Would remove scheduled task '$TaskName'" "Magenta"
        return
    }
    
    if (-not $Force) {
        $response = Read-Host "❓ Are you sure you want to remove the '$TaskName' scheduled task? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-ColorOutput "❌ Uninstallation cancelled." "Yellow"
            return
        }
    }
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-ColorOutput "✅ Scheduled task '$TaskName' removed successfully!" "Green"
        Write-ColorOutput "" "White"
        Write-ColorOutput "📝 Note: Log files in the 'logs' directory were not removed." "Gray"
        Write-ColorOutput "   You can manually delete them if desired." "Gray"
    } catch {
        Write-ColorOutput "❌ Failed to remove scheduled task: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main execution
try {
    Write-ColorOutput "🗑️  Augment Monitor Scheduled Task Uninstaller" "Red"
    Write-ColorOutput "" "White"

    if (-not (Test-Administrator)) {
        if ($WhatIf) {
            Write-ColorOutput "⚠️  Not running as Administrator (WhatIf mode - continuing anyway)" "Yellow"
        } else {
            Write-ColorOutput "⚠️  Administrator privileges required for removing scheduled tasks." "Yellow"
            Request-Elevation
            return
        }
    } else {
        Write-ColorOutput "✅ Running with Administrator privileges" "Green"
    }

    Remove-AugmentTask

} catch {
    Write-ColorOutput "❌ Uninstallation failed: $($_.Exception.Message)" "Red"
    exit 1
}
