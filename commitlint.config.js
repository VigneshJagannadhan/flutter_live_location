module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Allowed types — mirrors the bump logic in release.yml
    'type-enum': [
      2,
      'always',
      [
        'feat',   // minor bump (0.x.0)
        'fix',    // patch bump (0.0.x)
        'chore',  // no release (used by release bot)
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'revert',
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100],
  },
};
