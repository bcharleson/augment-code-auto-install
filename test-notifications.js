#!/usr/bin/env node

const { execSync } = require('child_process');
const chalk = require('chalk');

// Test script to simulate different scenarios
async function testNotifications() {
  console.log(chalk.blue('🧪 Testing Augment Monitor Notifications\n'));
  
  console.log(chalk.yellow('1. Testing native notification dialog...'));
  
  try {
    const script = `display dialog "This is a test notification for Augment Monitor

Current: 0.511.0
Latest: 0.512.0

Install this update?" with title "Augment Extension Update Available" buttons {"Cancel", "Install"} default button "Install" with icon note`;
    
    const result = execSync(`osascript -e '${script}'`, { 
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    });
    
    const match = result.match(/button returned:(.+)$/);
    const button = match ? match[1].trim() : 'Cancel';
    
    console.log(chalk.green(`✅ Notification test successful! User clicked: ${button}`));
    
  } catch (error) {
    console.log(chalk.red(`❌ Notification test failed: ${error.message}`));
  }
  
  console.log(chalk.yellow('\n2. Testing success notification...'));
  
  try {
    const script = `display dialog "Successfully updated to version 0.512.0

You may need to reload Cursor." with title "Augment Update Complete" buttons {"OK"} default button "OK" with icon note`;
    
    execSync(`osascript -e '${script}'`, { 
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    });
    
    console.log(chalk.green('✅ Success notification test completed!'));
    
  } catch (error) {
    console.log(chalk.red(`❌ Success notification test failed: ${error.message}`));
  }
  
  console.log(chalk.blue('\n🎯 How this works in cron mode:'));
  console.log(chalk.gray('• When running from cron (no terminal), native macOS dialogs appear'));
  console.log(chalk.gray('• You can approve/decline updates without opening terminal'));
  console.log(chalk.gray('• Success notifications confirm when updates complete'));
  console.log(chalk.gray('• No notifications when already up-to-date (to avoid spam)'));
  
  console.log(chalk.blue('\n📅 To test cron mode:'));
  console.log(chalk.gray('1. Set up cron job: ./install-cron.sh'));
  console.log(chalk.gray('2. Wait for next check (or manually trigger)'));
  console.log(chalk.gray('3. Native dialog will appear if update is available'));
  console.log(chalk.gray('4. Check logs: tail -f logs/cron.log'));
}

testNotifications().catch(console.error); 