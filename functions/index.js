// functions/index.js
const admin = require('firebase-admin');
admin.initializeApp();

const { generarCarnet } = require('./src/generarCarnet');

module.exports = { generarCarnet };
