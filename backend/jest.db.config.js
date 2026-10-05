const base = require('./jest.config');

module.exports = {
  ...base,
  testRegex: '.*\\.db-test\\.ts$',
  setupFiles: ['<rootDir>/test/setup-db-test-env.ts'],
};
