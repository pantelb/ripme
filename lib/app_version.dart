const String appVersion = String.fromEnvironment(
  'RIPME_VERSION',
  defaultValue: '1.0.0',
);

const String appBuildNumber = String.fromEnvironment(
  'RIPME_BUILD_NUMBER',
  defaultValue: '1',
);

const String releaseRepository = String.fromEnvironment(
  'RIPME_RELEASE_REPOSITORY',
  defaultValue: 'pantelb/ripme',
);
