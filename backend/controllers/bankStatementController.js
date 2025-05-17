const { processBankStatement } = require('../services/qwenTextExtractBankStatement');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

/**
 * Process a bank statement image
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const processBankStatementImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No file uploaded'
            });
        }

        // Save the uploaded file temporarily
        const fileExtension = path.extname(req.file.originalname);
        const fileName = `${uuidv4()}${fileExtension}`;
        const filePath = path.join(uploadsDir, fileName);
        
        fs.writeFileSync(filePath, req.file.buffer);

        // Process the bank statement
        const extractedData = await processBankStatement(filePath);

        // Clean up the temporary file
        fs.unlinkSync(filePath);

        // Return the extracted data directly
        res.json(extractedData);
    } catch (error) {
        console.error('Error processing bank statement:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing bank statement',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    processBankStatementImage
}; 