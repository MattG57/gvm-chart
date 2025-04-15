const { chromium } = require('playwright');

(async () => {
  const clientId = 'Iv23liFU7U02m6ptmy4D'; // replace if needed
  const redirectUri = 'https://meli-metrics.eastus2.cloudapp.azure.com/oauth2/callback';
  const state = 'debug-flow'; // or parse from earlier steps if needed

  const url = `https://github.com/login/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=user:email read:org&state=${state}`;

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on('framenavigated', async (frame) => {
    const loc = frame.url();
    if (loc.startsWith(redirectUri)) {
      console.log('\n✅ OAuth Callback URL:\n', loc);
      await browser.close();
    }
  });

  await page.goto(url);
})();

