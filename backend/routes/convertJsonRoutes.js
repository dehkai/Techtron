const express = require('express');
const router = express.Router();
const { Parser } = require('json2csv');
const fs = require('fs');
const path = require('path');

// POST /api/convertJson
router.post('/', (req, res) => {
    const inputArray = req.body;

    if (!Array.isArray(inputArray)) {
        return res.status(400).json({
            success: false,
            message: 'Expected an array of JSON objects.'
        });
    }

    try {
        // Define fields (optional: controls column order)
        const fields = ['date', 'type', 'description', 'amount'];
        const json2csvParser = new Parser({ fields });
        const csv = json2csvParser.parse(inputArray);

        // Create temporary file
        const fileName = `output-${Date.now()}.csv`;
        const filePath = path.join(__dirname, '..', 'tmp', fileName);

        // Ensure /tmp folder exists
        if (!fs.existsSync(path.join(__dirname, '..', 'tmp'))) {
            fs.mkdirSync(path.join(__dirname, '..', 'tmp'));
        }

        fs.writeFileSync(filePath, csv);

        // Send file to user
        res.download(filePath, fileName, (err) => {
            if (err) {
                console.error('File download error:', err);
            }
            // Delete file after sending
            fs.unlinkSync(filePath);
        });

    } catch (error) {
        console.error('Error during conversion:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to convert JSON to CSV'
        });
    }
});

module.exports = router;