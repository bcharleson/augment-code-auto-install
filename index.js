#!/usr/bin/env node

const { execSync } = require('child_process');
const fetch = require('node-fetch');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const semver = require('semver');
const chalk = require('chalk');

class AugmentMonitor {
  constructor() {
    this.extensionId = 'augment.vscode-augment';
    this.publisherId = 'augment';
    this.extensionName = 'vscode-augment';
    this.tempDir = path.join(__dirname, 'temp');
    this.isDryRun = process.argv.includes('--dry-run');
    this.isCronMode = !process.stdout.isTTY; // Detect if running from cron
    
    // Ensure temp directory exists
    if (!fs.existsSync(this.tempDir)) {
      fs.mkdirSync(this.tempDir);
    }
  }

  log(message, level = 'info') {
    const timestamp = new Date().toISOString();
    const colors = {
      info: chalk.blue,
      success: chalk.green,
      warning: chalk.yellow,
      error: chalk.red
    };
    
    console.log(`[${timestamp}] ${colors[level](level.toUpperCase())}: ${message}`);
  }

  async getCurrentVersion() {
    try {
      this.log('Checking current Augment version...');
      const output = execSync('cursor --list-extensions --show-versions', { 
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore']
      });
      
      const match = output.match(/augment\.vscode-augment@(\d+\.\d+\.\d+)/);
      const version = match ? match[1] : null;
      
      if (version) {
        this.log(`Current version: ${version}`, 'info');
        return version;
      } else {
        this.log('Augment extension not found in Cursor', 'warning');
        return null;
      }
    } catch (error) {
      this.log(`Failed to get current version: ${error.message}`, 'error');
      throw error;
    }
  }

  async getLatestVersion() {
    try {
      this.log('Fetching latest version from VS Code Marketplace...');
      
      // Try the public API first
      const response = await fetch('https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json;api-version=3.0-preview.1',
          'User-Agent': 'augment-monitor/1.0.0'
        },
        body: JSON.stringify({
          filters: [{
            criteria: [
              { filterType: 7, value: this.extensionId }
            ],
            pageNumber: 1,
            pageSize: 1,
            sortBy: 0,
            sortOrder: 0
          }],
          assetTypes: [],
          flags: 0x200
        })
      });

      if (!response.ok) {
        this.log(`API failed with ${response.status}, trying web scraping fallback...`, 'warning');
        return await this.getLatestVersionFallback();
      }

      const data = await response.json();
      
      if (!data.results || !data.results[0] || !data.results[0].extensions || !data.results[0].extensions[0]) {
        this.log('No extension found in API response, trying fallback...', 'warning');
        return await this.getLatestVersionFallback();
      }

      const extension = data.results[0].extensions[0];
      const version = extension.versions[0].version;
      
      this.log(`Latest version: ${version}`, 'info');
      return version;
    } catch (error) {
      this.log(`API failed: ${error.message}, trying fallback...`, 'warning');
      return await this.getLatestVersionFallback();
    }
  }

  async getLatestVersionFallback() {
    try {
      this.log('Using web scraping fallback...');
      
      const response = await fetch(`https://marketplace.visualstudio.com/items?itemName=${this.extensionId}`, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
      });

      if (!response.ok) {
        throw new Error(`Marketplace page failed with status: ${response.status}`);
      }

      const html = await response.text();
      
      // Look for version in the HTML - multiple patterns to try
      const versionPatterns = [
        /"version":"([^"]+)"/,
        /Version\s+([0-9]+\.[0-9]+\.[0-9]+)/i,
        /"Version":"([^"]+)"/,
        /data-version="([^"]+)"/
      ];

      for (const pattern of versionPatterns) {
        const match = html.match(pattern);
        if (match && match[1]) {
          const version = match[1];
          this.log(`Latest version (fallback): ${version}`, 'info');
          return version;
        }
      }

      throw new Error('Could not find version in marketplace page');
    } catch (error) {
      this.log(`Fallback also failed: ${error.message}`, 'error');
      throw error;
    }
  }

  async sendNativeNotification(title, message, buttons = ['OK']) {
    try {
      if (this.isDryRun) {
        this.log(`DRY RUN: Would send notification: ${title} - ${message}`, 'warning');
        return 'OK';
      }

      // Use osascript to show native macOS notification with dialog
      const buttonList = buttons.map(b => `"${b}"`).join(', ');
      const script = `display dialog "${message}" with title "${title}" buttons {${buttonList}} default button "${buttons[buttons.length - 1]}" with icon note`;
      
      const result = execSync(`osascript -e '${script}'`, { 
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore']
      });
      
      // Extract button result
      const match = result.match(/button returned:(.+)$/);
      return match ? match[1].trim() : buttons[0];
    } catch (error) {
      this.log(`Native notification failed: ${error.message}`, 'warning');
      return null; // Fallback to CLI prompt
    }
  }

  async promptUser(currentVersion, latestVersion) {
    // If running from cron (no TTY), use native notifications
    if (this.isCronMode) {
      this.log('Running in cron mode, using native notifications', 'info');
      
      const message = `Current: ${currentVersion || 'Not installed'}\\nLatest: ${latestVersion}\\n\\nInstall this update?`;
      const result = await this.sendNativeNotification(
        'Augment Extension Update Available',
        message,
        ['Cancel', 'Install']
      );
      
      const proceed = result === 'Install';
      this.log(proceed ? 'User approved update via notification' : 'User declined update via notification', proceed ? 'success' : 'info');
      return proceed;
    }

    // CLI mode for interactive terminals
    return new Promise((resolve) => {
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });

      console.log('\n' + chalk.cyan('🚀 Augment Extension Update Available!'));
      console.log(chalk.gray('─'.repeat(50)));
      console.log(`Current version: ${chalk.yellow(currentVersion || 'Not installed')}`);
      console.log(`Latest version:  ${chalk.green(latestVersion)}`);
      console.log(chalk.gray('─'.repeat(50)));
      
      rl.question(chalk.bold('\nWould you like to download and install this update? (y/N): '), (answer) => {
        rl.close();
        const proceed = answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes';
        
        if (proceed) {
          this.log('User approved update', 'success');
        } else {
          this.log('User declined update', 'info');
        }
        
        resolve(proceed);
      });
    });
  }

  async downloadVsix(version) {
    try {
      this.log(`Downloading VSIX file for version ${version}...`);

      if (this.isDryRun) {
        this.log('DRY RUN: Would download VSIX file', 'warning');
        return path.join(this.tempDir, `${this.extensionId}-${version}.vsix`);
      }

      const downloadUrl = `https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${this.publisherId}/vsextensions/${this.extensionName}/${version}/vspackage`;

      const response = await fetch(downloadUrl, {
        headers: {
          'Accept': 'application/octet-stream',
          'User-Agent': 'VSCode/1.85.0 (Windows NT 10.0; Win64; x64)',
          'Accept-Encoding': 'gzip, deflate, br'
        }
      });

      if (!response.ok) {
        throw new Error(`Download failed with status: ${response.status}`);
      }

      const fileName = `${this.extensionId}-${version}.vsix`;
      const filePath = path.join(this.tempDir, fileName);

      const buffer = await response.buffer();
      fs.writeFileSync(filePath, buffer);

      const fileSizeMB = (buffer.length / (1024 * 1024)).toFixed(2);
      this.log(`Downloaded ${fileName} (${fileSizeMB} MB)`, 'success');

      return filePath;
    } catch (error) {
      this.log(`Download failed: ${error.message}`, 'error');
      throw error;
    }
  }

  async installExtension(vsixPath) {
    try {
      this.log('Installing extension via Cursor CLI...');
      
      if (this.isDryRun) {
        this.log('DRY RUN: Would install extension', 'warning');
        return true;
      }

      execSync(`cursor --install-extension "${vsixPath}"`, {
        stdio: 'inherit'
      });
      
      this.log('Extension installation completed', 'success');
      return true;
    } catch (error) {
      this.log(`Installation failed: ${error.message}`, 'error');
      throw error;
    }
  }

  async verifyInstallation(expectedVersion) {
    try {
      this.log('Verifying installation...');
      
      if (this.isDryRun) {
        this.log('DRY RUN: Would verify installation', 'warning');
        return true;
      }

      // Wait a moment for the extension to be recognized
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const installedVersion = await this.getCurrentVersion();
      
      if (installedVersion === expectedVersion) {
        this.log(`Installation verified! Running version ${installedVersion}`, 'success');
        return true;
      } else {
        throw new Error(`Version mismatch: expected ${expectedVersion}, got ${installedVersion}`);
      }
    } catch (error) {
      this.log(`Installation verification failed: ${error.message}`, 'error');
      throw error;
    }
  }

  cleanupFile(filePath) {
    try {
      if (this.isDryRun) {
        this.log('DRY RUN: Would delete VSIX file', 'warning');
        return;
      }

      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        this.log(`Cleaned up: ${path.basename(filePath)}`, 'success');
      }
    } catch (error) {
      this.log(`Cleanup failed: ${error.message}`, 'warning');
    }
  }

  async run() {
    try {
      this.log('Starting Augment extension update check...', 'info');
      
      // Get current and latest versions
      const [currentVersion, latestVersion] = await Promise.all([
        this.getCurrentVersion(),
        this.getLatestVersion()
      ]);

      // Compare versions
      if (!currentVersion) {
        this.log('Augment extension not installed, proceeding with installation...', 'warning');
      } else if (!semver.gt(latestVersion, currentVersion)) {
        this.log(`Already up to date! (${currentVersion})`, 'success');
        
        // In cron mode, only notify if explicitly configured
        if (this.isCronMode) {
          this.log('Up to date - no notification needed for cron mode', 'info');
        }
        return;
      }

      // Prompt user for approval
      const userApproved = await this.promptUser(currentVersion, latestVersion);
      
      if (!userApproved) {
        this.log('Update cancelled by user', 'info');
        return;
      }

      let vsixPath = null;

      try {
        // Download VSIX
        vsixPath = await this.downloadVsix(latestVersion);
        
        // Install extension
        await this.installExtension(vsixPath);
        
        // Verify installation
        await this.verifyInstallation(latestVersion);
        
        // Success message
        console.log('\n' + chalk.green('✅ Update completed successfully!'));
        console.log(chalk.gray('─'.repeat(40)));
        console.log(`${chalk.green('●')} Downloaded version ${latestVersion}`);
        console.log(`${chalk.green('●')} Installed via Cursor CLI`);
        console.log(`${chalk.green('●')} Installation verified`);
        console.log(`${chalk.green('●')} Temporary files cleaned up`);
        console.log('\nYou may need to reload Cursor for all changes to take effect.');

        // Send success notification in cron mode
        if (this.isCronMode) {
          await this.sendNativeNotification(
            'Augment Update Complete',
            `Successfully updated to version ${latestVersion}\\n\\nYou may need to reload Cursor.`,
            ['OK']
          );
        }

      } finally {
        // Always cleanup the downloaded file
        if (vsixPath) {
          this.cleanupFile(vsixPath);
        }
      }

    } catch (error) {
      this.log(`Update process failed: ${error.message}`, 'error');
      console.log('\n' + chalk.red('❌ Update failed'));
      console.log(`Error: ${error.message}`);
      process.exit(1);
    }
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error(chalk.red('Uncaught Exception:'), error.message);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('Unhandled Rejection at:'), promise, chalk.red('reason:'), reason);
  process.exit(1);
});

// Run the monitor
if (require.main === module) {
  const monitor = new AugmentMonitor();
  monitor.run();
}

module.exports = AugmentMonitor; 