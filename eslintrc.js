// Global ESLint file for basic eslintery.
// Ideally a new root eslint file is created in each project,
// but sometimes I just need some syntax checking.

module.exports = {
  root: true,

  parser: 'babel-eslint',

  parserOptions: {
    ecmaVersion: 6,
  },

  extends: [
    'eslint:recommended',
  ],

  env: {
    node: true,
    es6: true,
  },

  rules: {
    // Blep.
    'brace-style': ['warn', 'stroustrup'],

    // Because some projects require semis and some don't, I'm just turning this off.
    'semi': ['off'],
  },
};
