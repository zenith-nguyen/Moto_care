const base = require('./jest.config');

module.exports = {
  ...base,
  testRegex: '.*\\.db-test\\.ts$',
};
