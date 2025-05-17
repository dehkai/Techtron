// controllers/receiptController.js

const express = require('express');
const multer = require('multer');
const receiptService = require('../services/qwenTextExtractReceipt');

// Set up multer for file uploads
const storage = multer.memoryStorage(); // Store image in memory buffer
const upload = multer({ storage });

// Controller function to handle receipt upload
async function extractAndSaveReceipt(req, res) {
  // Your logic here
}

// EXPORT BOTH FUNCTIONS AND MIDDLEWARE
module.exports = {
  extractAndSaveReceipt,
  upload // 👈 This must be exported!
};