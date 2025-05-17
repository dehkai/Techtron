const express = require('express');
const router = express.Router();
const multer = require('multer');
const BankStatementController = require('../controllers/bankStatementController');
const { extractBankStatementData } = require('../services/qwenTextExtractBankStatement');

// Configure multer for file upload
const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit for bank statements
    },
    fileFilter: (req, file, cb) => {
        // Accept images and PDFs
        if (file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf') {
            cb(null, true);
        } else {
            cb(new Error('Only image and PDF files are allowed'));
        }
    }
});

// Routes
router.post('/process', upload.single('statement'), BankStatementController.processBankStatementImage);

// Test route for the API
router.post('/test-api', async (req, res) => {
    try {
        // Get test image path from request
        const { imagePath } = req.body;
        
        if (!imagePath) {
            return res.status(400).json({
                success: false,
                message: 'Image path is required'
            });
        }
        
        // Call the API
        const result = await extractBankStatementData(imagePath);
        
        res.json({
            success: true,
            result,
            apiDetails: {
                endpoint: process.env.QWEN_API_URL || 'Not configured',
                model: 'bank-statement'
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

module.exports = router;