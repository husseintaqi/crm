# Twenty CRM Deployment to Hetzner
# This script will guide you through deploying to your server

$serverIP = "46.62.138.89"
$serverUser = "root"
$domain = "edu.automatespot.com"

Write-Host "🚀 Twenty CRM Deployment Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# First, let's commit the deployment script to git and push it
Write-Host "📝 Preparing deployment files..." -ForegroundColor Yellow
git add deploy-to-hetzner.sh
git commit -m "Add deployment script" 2>$null
git push origin main 2>$null

Write-Host ""
Write-Host "🔐 Connecting to server: $serverIP" -ForegroundColor Yellow
Write-Host "💡 You'll be prompted for the password: ia9vu33jiFUV" -ForegroundColor Green
Write-Host ""

# Create the SSH command string
$sshCommand = @"
cd /root && \
curl -o deploy.sh https://raw.githubusercontent.com/husseintaqi/crm/main/deploy-to-hetzner.sh && \
chmod +x deploy.sh && \
bash deploy.sh
"@

Write-Host "📋 Commands that will be executed on the server:" -ForegroundColor Cyan
Write-Host $sshCommand -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host

# Execute SSH command
ssh -o "StrictHostKeyChecking=no" "$serverUser@$serverIP" $sshCommand

Write-Host ""
Write-Host "✅ Deployment initiated!" -ForegroundColor Green
Write-Host "🌐 Your CRM will be available at: https://$domain" -ForegroundColor Cyan
