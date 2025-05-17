const express = require('express');
const cors = require('cors');
const https = require('https');

const bankStatementRoutes = require('./routes/bankStatementRoutes');
const receiptRoutes = require('./routes/receiptRoutes');


const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/bank-statements', bankStatementRoutes);
app.use('/api/receipts', receiptRoutes);

// API Testing route - checks API configuration
app.get('/api/check-api-config', (req, res) => {
  try {
    const apiUrl = process.env.QWEN_API_URL;
    const apiKey = process.env.QWEN_API_KEY;
    
    if (!apiUrl || !apiKey) {
      return res.status(400).json({
        success: false,
        message: 'API configuration is incomplete',
        config: {
          apiUrl: apiUrl ? 'Configured' : 'Missing',
          apiKey: apiKey ? 'Configured (masked)' : 'Missing'
        }
      });
    }
    
    // Mask the API key for security
    const maskedApiKey = apiKey.substring(0, 4) + '...' + apiKey.substring(apiKey.length - 4);
    
    // Parse the API URL to check its validity
    try {
      const url = new URL(apiUrl);
      
      // Return success without actually making an API call
      return res.json({
        success: true,
        message: 'API configuration looks valid',
        config: {
          apiUrl: url.origin,
          apiKeyPrefix: maskedApiKey,
          isSecure: url.protocol === 'https:'
        }
      });
    } catch (urlError) {
      return res.status(400).json({
        success: false,
        message: 'Invalid API URL format',
        error: urlError.message
      });
    }
  } catch (err) {
    console.error('Error checking API config:', err);
    return res.status(500).json({
      success: false,
      message: 'Error checking API configuration',
      error: err.message
    });
  }
});

// Test the API connectivity with a simple ping
app.get('/api/test-api-connectivity', async (req, res) => {
  try {
    const apiUrl = process.env.QWEN_API_URL;
    const apiKey = process.env.QWEN_API_KEY;
    
    if (!apiUrl || !apiKey) {
      return res.status(400).json({
        success: false,
        message: 'API configuration is incomplete'
      });
    }
    
    // Create a simple promise-based head request
    const checkUrl = async (url) => {
      return new Promise((resolve, reject) => {
        const req = https.request(url, { method: 'HEAD' }, (res) => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers
          });
        });
        
        req.on('error', (error) => {
          reject(error);
        });
        
        req.end();
      });
    };
    
    try {
      const urlObj = new URL(apiUrl);
      const result = await checkUrl(urlObj.origin);
      
      return res.json({
        success: true,
        message: 'Successfully connected to API endpoint',
        details: {
          status: result.statusCode,
          server: result.headers?.server || 'Unknown',
          endpoint: urlObj.origin
        }
      });
    } catch (connErr) {
      return res.status(503).json({
        success: false,
        message: 'Failed to connect to API endpoint',
        error: connErr.message
      });
    }
    
  } catch (err) {
    console.error('Error testing API connectivity:', err);
    return res.status(500).json({
      success: false,
      message: 'Error testing API connectivity',
      error: err.message
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

module.exports = app;