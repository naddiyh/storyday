param([string]$BaseUrl = 'http://127.0.0.1:5175')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force output/playwright | Out-Null
npx --yes --package @playwright/cli playwright-cli -s=visual open $BaseUrl --browser msedge
npx --yes --package @playwright/cli playwright-cli -s=visual resize 390 844
Start-Sleep -Seconds 5
foreach ($route in @('calendar','search','create','recap','profile','themes')) {
    npx --yes --package @playwright/cli playwright-cli -s=visual goto "$BaseUrl/#/$route"
    Start-Sleep -Seconds 2
    npx --yes --package @playwright/cli playwright-cli -s=visual snapshot
    npx --yes --package @playwright/cli playwright-cli -s=visual screenshot --filename "output/playwright/$route-final.png"
}
npx --yes --package @playwright/cli playwright-cli -s=visual console error
