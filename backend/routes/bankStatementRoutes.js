const express = require('express');
const router = express.Router();
const multer = require('multer');
const BankStatementController = require('../controllers/bankStatementController');

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

module.exports = router; 