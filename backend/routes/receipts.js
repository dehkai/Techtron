const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { processReceipt } = require('../services/qwenReceipts');

// Configure multer for file upload
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    fileFilter: function (req, file, cb) {
        // Accept images only
        if (!file.originalname.match(/\.(jpg|jpeg|png)$/)) {
            return cb(new Error('Only image files are allowed!'), false);
        }
        cb(null, true);
    }
}).single('receipt');

/**
 * @route POST /api/receipts/process
 * @desc Process a receipt image and extract information
 * @access Public
 */
router.post('/process', (req, res) => {
    upload(req, res, async function(err) {
        if (err instanceof multer.MulterError) {
            // A Multer error occurred when uploading
            return res.status(400).json({ error: err.message });
        } else if (err) {
            // An unknown error occurred
            return res.status(500).json({ error: err.message });
        }

        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        try {
            const receiptData = await processReceipt(req.file.path);
            res.json(receiptData);
        } catch (error) {
            console.error('Error processing receipt:', error);
            res.status(500).json({ error: error.message });
        }
    });
});

/**
 * @route GET /api/receipts
 * @desc Get all processed receipts
 * @access Public
 */
router.get('/', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const query = 'SELECT * FROM receipts ORDER BY date DESC';
        
        db.query(query, (err, results) => {
            if (err) {
                throw new Error('Error fetching receipts: ' + err.message);
            }
            res.json(results);
        });
    } catch (error) {
        console.error('Error fetching receipts:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route GET /api/receipts/:id
 * @desc Get a specific receipt by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const query = 'SELECT * FROM receipts WHERE id = ?';
        
        db.query(query, [req.params.id], (err, results) => {
            if (err) {
                throw new Error('Error fetching receipt: ' + err.message);
            }
            if (results.length === 0) {
                return res.status(404).json({ error: 'Receipt not found' });
            }
            res.json(results[0]);
        });
    } catch (error) {
        console.error('Error fetching receipt:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route DELETE /api/receipts/:id
 * @desc Delete a receipt
 * @access Public
 */
router.delete('/:id', async (req, res) => {
    try {
        const db = req.app.locals.db;
        const query = 'DELETE FROM receipts WHERE id = ?';
        
        db.query(query, [req.params.id], (err, result) => {
            if (err) {
                throw new Error('Error deleting receipt: ' + err.message);
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'Receipt not found' });
            }
            res.json({ message: 'Receipt deleted successfully' });
        });
    } catch (error) {
        console.error('Error deleting receipt:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 