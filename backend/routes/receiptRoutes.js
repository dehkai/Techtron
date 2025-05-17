const express = require('express');
const receiptController = require('../controllers/receiptController');
const receiptService = require('../services/qwenTextExtractReceipt');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Configure storage for the test endpoint
const testStorage = multer.memoryStorage();
const testUpload = multer({ 
  storage: testStorage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only images
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// This will become: POST /api/receipts/upload
router.post('/upload', receiptController.upload.single('receipt'), receiptController.extractAndSaveReceipt);

// Test route
router.get('/test-receipt', async (req, res) => {
  try {
    const dummyImageUrl = 'https://dashscope.oss-cn-beijing.aliyuncs.com/images/dog_and_girl.jpeg ';
    const result = await receiptController.extractReceiptData(dummyImageUrl);
    res.json({ result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// New route to test Qwen API directly - accepts JSON with imageUrl
router.post('/test-api', async (req, res) => {
  try {
    // Get an image URL from the request body
    const { imageUrl } = req.body;
    
    if (!imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Image URL is required'
      });
    }
    
    // Call the cloud model API
    const result = await receiptService.extractReceiptData(imageUrl);
    
    res.json({
      success: true,
      result,
      apiDetails: {
        endpoint: process.env.QWEN_API_URL || 'Not configured',
        model: 'qwen-vl-max'
      }
    });
  } catch (error) {
    console.error('Error testing API:', error);
    res.status(500).json({
      success: false,
      message: 'Error testing cloud model API',
      error: error.message
    });
  }
});

// New route to test Qwen API with form data file upload
router.post('/test-api-upload', testUpload.single('receipt'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    console.log('File upload received:', {
      filename: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    });

    // Create temp uploads directory if it doesn't exist
    const uploadsDir = path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Generate a unique filename
    const fileExtension = path.extname(req.file.originalname);
    const fileName = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(uploadsDir, fileName);
    
    // Write the file to disk temporarily
    fs.writeFileSync(filePath, req.file.buffer);
    console.log(`Temporary file saved at: ${filePath}`);
    
    // Convert to base64 for the API
    const base64Image = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    console.log('Image converted to base64, length:', base64Image.length);
    
    // Process the image
    console.log('Calling receipt service to extract data...');
    const result = await receiptService.extractReceiptData(base64Image);
    
    // Remove the temporary file
    fs.unlinkSync(filePath);
    
    res.json({
      success: true,
      result,
      apiDetails: {
        endpoint: process.env.QWEN_API_URL || 'Not configured',
        model: 'qwen-vl-max',
        filename: req.file.originalname
      }
    });
    
  } catch (error) {
    console.error('Error testing API with file upload:', error);
    res.status(500).json({
      success: false,
      message: 'Error testing cloud model API with file upload',
      error: error.message,
      apiConfig: {
        apiUrl: process.env.QWEN_API_URL ? 'Configured' : 'Missing',
        apiKey: process.env.QWEN_API_KEY ? 'Configured (hidden)' : 'Missing'
      }
    });
  }
});

module.exports = router;