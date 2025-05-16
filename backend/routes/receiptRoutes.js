const express = require('express');
const router = express.Router();
const multer = require('multer');
const ReceiptController = require('../controllers/receiptController');

// Configure multer for file upload
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// Routes
router.post('/', upload.single('receipt'), ReceiptController.createReceipt);
router.get('/', ReceiptController.getReceipts);
router.get('/:id', ReceiptController.getReceipt);
router.put('/:id', ReceiptController.updateReceipt);
router.delete('/:id', ReceiptController.deleteReceipt);

module.exports = router; 