# Augment Extension Monitor

Automated monitoring and updating system for the Augment VS Code extension in Cursor.

## Features

- 🔍 **Automatic Version Detection** - Monitors VS Code Marketplace for new releases
- 👤 **Human-in-the-Loop** - Always prompts for user approval before updating
- 📦 **Automated Download** - Downloads VSIX files from marketplace
- ⚡ **CLI Installation** - Uses Cursor CLI for seamless installation
- ✅ **Verification** - Confirms successful installation before cleanup
- 🧹 **Auto Cleanup** - Removes temporary VSIX files after installation
- 📅 **Cron Scheduling** - Runs automatically in background

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Test the Script
```bash
# Dry run to test without making changes
npm test

# Manual check for updates
npm start
```

### 3. Setup Automated Monitoring

#### Linux/macOS (Cron)
```bash
# Install cron job (runs every 6 hours)
chmod +x install-cron.sh
./install-cron.sh
```

#### Windows (Scheduled Task)
```powershell
# Test the installation (WhatIf mode - no changes made)
npm run test-task

# Install Windows scheduled task (automatically requests UAC elevation)
npm run install-task

# Alternative schedules:
npm run install-task-work    # Daily during work days at 9 AM
npm run install-task-daily   # Daily at 9 AM

# Check task status
npm run task-status

# Uninstall task (automatically requests UAC elevation)
npm run uninstall-task
```

**Note:** The Windows scripts will automatically prompt for Administrator privileges via UAC when needed. Simply click "Yes" when prompted.

## Usage

### Manual Usage
```bash
# Check for updates and prompt for installation
node index.js

# Dry run (test without making changes)
node index.js --dry-run
```

### Automated Usage
The cron job will automatically:
1. Check for new Augment extension versions every 6 hours
2. Compare with your currently installed version
3. If newer version found, prompt you via CLI
4. Upon approval: download → install → verify → cleanup

## User Interaction Flow

When a new version is detected:

```
🚀 Augment Extension Update Available!
──────────────────────────────────────────────────
Current version: 0.511.0
Latest version:  0.512.0
──────────────────────────────────────────────────

Would you like to download and install this update? (y/N):
```

If you choose **Yes**:
1. ⬬ Downloads VSIX file (e.g., `augment.vscode-augment-0.512.0.vsix`)
2. 🔧 Installs via `cursor --install-extension`
3. ✅ Verifies installation by checking version
4. 🗑️ Deletes temporary VSIX file
5. 🎉 Shows success confirmation

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "checkInterval": "0 */6 * * *",  // Every 6 hours
  "autoDownload": false,           // Always prompt first
  "logLevel": "info",
  "maxRetries": 3
}
```

### Available Schedules
- `"0 */6 * * *"` - Every 6 hours (default)
- `"0 9-17/2 * * 1-5"` - Every 2 hours during work days
- `"0 9 * * *"` - Daily at 9 AM
- `"0 */3 * * *"` - Every 3 hours

## Logs

View monitoring activity:
```bash
# View recent activity
tail -f logs/cron.log

# View all logs
cat logs/cron.log
```

## Troubleshooting

### Check Current Cron Jobs
```bash
crontab -l
```

### Remove Cron Job
```bash
crontab -l | grep -v '/path/to/augment-monitor/index.js' | crontab -
```

### Manual Installation Test
```bash
# Check if Cursor CLI works
cursor --list-extensions --show-versions

# Test marketplace API
curl -X POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery
```

### Common Issues

1. **"command not found: cursor"**
   - Ensure Cursor is installed and CLI is available in PATH

2. **"Extension not found"**
   - Check if Augment extension is installed in Cursor
   - Run: `cursor --list-extensions`

3. **"Download failed"**
   - Check internet connection
   - Verify VS Code Marketplace is accessible

4. **"Installation failed"**
   - Ensure Cursor is not running during installation
   - Check file permissions in temp directory

### Windows-Specific Issues

1. **"Execution Policy" errors**
   - Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
   - Or use the npm scripts which bypass execution policy

2. **"Access Denied" when creating scheduled task**
   - Run PowerShell as Administrator
   - Use: `npm run install-task` (requires admin PowerShell)

3. **Task not running automatically**
   - Check task status: `npm run task-status`
   - Verify task settings: `Get-ScheduledTask -TaskName "AugmentMonitor" | Get-ScheduledTaskInfo`
   - Check Windows Event Viewer for task scheduler errors

## File Structure

```
augment-monitor/
├── index.js              # Main monitoring script
├── package.json           # Dependencies and scripts
├── config.json           # Configuration settings
├── install-cron.sh       # Cron job setup script
├── temp/                 # Temporary VSIX downloads (auto-created)
├── logs/                 # Log files (auto-created)
└── README.md             # This file
```

## Security Notes

- Script only downloads from official VS Code Marketplace
- Always prompts before making changes
- Temporary files are cleaned up immediately after use
- No sensitive data is stored or transmitted

## Customization

The script can be easily modified to monitor other extensions by changing:
- `extensionId` in the constructor
- `publisherId` and `extensionName` for download URLs

## Support

For issues or questions:
1. Check the logs: `tail -f logs/cron.log`
2. Test manually: `npm test`
3. Verify Cursor CLI: `cursor --help` 