param([string]$BaseUrl = 'http://127.0.0.1:5175')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force output/playwright/planner | Out-Null
Start-Transcript -Path output/playwright/planner/run.log -Force
Set-Content output/playwright/planner/cli-results.log '' -Encoding Unicode
try {
    npx --yes --package @playwright/cli playwright-cli -s=planner open $BaseUrl --browser msedge | Tee-Object -FilePath output/playwright/planner/cli-results.log -Append
    if ($LASTEXITCODE -ne 0) { throw 'Browser launch failed' }
    # Batch only navigation and screenshots. Interactive checks use fresh CLI snapshot refs.
    foreach ($size in @(@(320,568), @(390,844), @(768,1024))) {
        $captureCode = @"
async (page) => {
  const errors = [];
  const listener = error => errors.push(error.message);
  page.on('pageerror', listener);
  const captures = [];
  await page.setViewportSize({ width: $($size[0]), height: $($size[1]) });
  for (const route of ['calendar','search','create','recap','profile','themes','schedule','focus/setup']) {
    await page.goto('$BaseUrl/#/' + route);
    await page.waitForSelector('flt-glass-pane', { state: 'attached' });
    await page.waitForFunction(() => document.title === 'Lenote');
    await page.waitForTimeout(1800);
    const path = 'output/playwright/planner/$($size[0])x$($size[1])-' + route.replaceAll('/', '-') + '.png';
    await page.screenshot({ path, scale: 'css' });
    captures.push({ route, path, viewport: page.viewportSize(), title: await page.title() });
  }
  page.off('pageerror', listener);
  if (errors.length) throw new Error(errors.join('; '));
  return { captures, pageErrors: errors };
}
"@
        $capturePath = "output/playwright/planner/capture-$($size[0])x$($size[1]).js"
        $captureCode | Set-Content $capturePath
        npx --yes --package @playwright/cli playwright-cli -s=planner run-code --filename $capturePath | Tee-Object -FilePath output/playwright/planner/cli-results.log -Append
        if ($LASTEXITCODE -ne 0) { throw 'Responsive capture failed' }
        npx --yes --package @playwright/cli playwright-cli -s=planner snapshot | Tee-Object -FilePath output/playwright/planner/cli-results.log -Append
    }
    npx --yes --package @playwright/cli playwright-cli -s=planner console error | Tee-Object -FilePath output/playwright/planner/cli-results.log -Append
} finally {
    Stop-Transcript
}
