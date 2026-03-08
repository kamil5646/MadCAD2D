const { notarize } = require('@electron/notarize');

exports.default = async function notarizeMac(context) {
  const { electronPlatformName, appOutDir, packager } = context;

  if (electronPlatformName !== 'darwin') {
    return;
  }

  const appleId = process.env.APPLE_ID;
  const applePassword = process.env.APPLE_APP_SPECIFIC_PASSWORD;
  const appleTeamId = process.env.APPLE_TEAM_ID;

  if (!appleId || !applePassword || !appleTeamId) {
    console.warn(
      '[notarize] Pomijam notaryzację: brak APPLE_ID / APPLE_APP_SPECIFIC_PASSWORD / APPLE_TEAM_ID.'
    );
    return;
  }

  const appName = packager.appInfo.productFilename;
  const appPath = `${appOutDir}/${appName}.app`;

  await notarize({
    appBundleId: packager.appInfo.id,
    appPath,
    appleId,
    appleIdPassword: applePassword,
    teamId: appleTeamId,
  });
};
