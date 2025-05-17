const mysql = require('mysql');
const fs = require('fs');
const OpenAI = require('openai');

// Create OpenAI client
const openai = new OpenAI({
    apiKey: process.env.QWEN_API_KEY,
    baseURL: process.env.QWEN_API_URL || 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1'
});

// Create a connection to Alibaba Cloud SQL Database only if DB_HOST is configured
let db;
if (process.env.DB_HOST) {
    db = mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
    });
}

/**
 * Standardizes date format to YYYY-MM-DD
 * @param {string} dateStr - Date string in various formats
 * @returns {string} - Standardized date in YYYY-MM-DD format
 */
function standardizeDate(dateStr) {
    // Handle MM/YY format
    if (/^\d{2}\/\d{2}$/.test(dateStr)) {
        const [month, year] = dateStr.split('/');
        return `20${year}-${month}-01`; // Default to first day of month
    }
    
    // Handle DD/MM/YY format
    if (/^\d{2}\/\d{2}\/\d{2}$/.test(dateStr)) {
        const [day, month, year] = dateStr.split('/');
        return `20${year}-${month}-${day}`;
    }
    
    // Handle DD/MM/YYYY format
    if (/^\d{2}\/\d{2}\/\d{4}$/.test(dateStr)) {
        const [day, month, year] = dateStr.split('/');
        return `${year}-${month}-${day}`;
    }
    
    // Handle MM/DD/YYYY format
    if (/^\d{2}\/\d{2}\/\d{4}$/.test(dateStr)) {
        const [month, day, year] = dateStr.split('/');
        return `${year}-${month}-${day}`;
    }
    
    return dateStr; // Return as is if no pattern matches
}

/**
 * Generates a detailed prompt for receipt extraction
 * @returns {string} - Structured prompt for the model
 */
function generateExtractionPrompt() {
    return `Please analyze this receipt image and extract transaction information. The receipt may be in various formats:

1. Date Formats to Handle:
   - DD/MM/YYYY (e.g., 25/12/2023)
   - MM/DD/YYYY (e.g., 12/25/2023)
   - DD/MM/YY (e.g., 25/12/23)
   - MM/YY (e.g., 12/23)
   - YYYY-MM-DD (e.g., 2023-12-25)

2. For each receipt, identify:
   - Date (convert to YYYY-MM-DD format)
   - Merchant name
   - Total amount
   - Description (brief summary of items purchased)

3. Important guidelines:
   - Skip any header/footer information
   - Focus on actual transaction details
   - For MM/YY format, use the first day of the month
   - Remove all currency symbols and commas from amounts
   - Keep description concise but informative

4. Output format:
   Each receipt should be structured as:
   {
     "date": "YYYY-MM-DD",
     "merchant": "merchant name",
     "amount": numeric_value,
     "description": "brief summary of items"
   }

Please ensure high accuracy in the extraction and maintain chronological order.`;
}

/**
 * Extracts receipt data from an image file by calling Model Studio API
 * @param {string} imagePath - Path to the receipt image
 * @returns {Promise<Object>} - Extracted receipt data
 */
async function extractReceiptData(imagePath) {
    try {
        // Read the image file as base64
        const imageBuffer = fs.readFileSync(imagePath);
        const base64Image = imageBuffer.toString('base64');

        // Generate the extraction prompt
        const extractionPrompt = generateExtractionPrompt();

        console.log('Sending request to Qwen API...');
        
        // Make API request using OpenAI SDK
        const response = await openai.chat.completions.create({
            model: 'qwen-vl-max',
            messages: [
                {
                    role: 'system',
                    content: [{ 
                        type: 'text', 
                        text: 'You are a specialized receipt parser. Extract all receipt details and return them as a raw JSON object. Do not use markdown formatting, code blocks, or any other text formatting. Return only the JSON object.' 
                    }]
                },
                {
                    role: 'user',
                    content: [
                        {
                            type: 'image_url',
                            image_url: {
                                url: `data:image/jpeg;base64,${base64Image}`
                            }
                        },
                        {
                            type: 'text',
                            text: extractionPrompt
                        }
                    ]
                }
            ],
            parameters: {
                temperature: 0.1,
                max_tokens: 2000,
                top_p: 0.9,
                response_format: { type: "json_object" }
            }
        });

        console.log('Received response from Qwen API');
        console.log('Raw response:', JSON.stringify(response, null, 2));

        let extractedData;
        try {
            const content = response.choices[0].message.content;
            console.log('API response content:', content);
            
            // Clean the content of any markdown formatting
            const cleanContent = content.replace(/```json\n?|\n?```/g, '').trim();
            console.log('Cleaned content:', cleanContent);
            
            // Parse the content as JSON
            extractedData = JSON.parse(cleanContent);
            console.log('Parsed JSON data:', JSON.stringify(extractedData, null, 2));

            // Post-process the extracted data
            if (extractedData.date) {
                extractedData.date = standardizeDate(extractedData.date);
            }

            // Ensure amount is numeric
            if (extractedData.amount) {
                extractedData.amount = parseFloat(extractedData.amount.toString().replace(/[^0-9.-]/g, ''));
            }

            console.log('Final processed data:', JSON.stringify(extractedData, null, 2));
            return extractedData;
        } catch (parseError) {
            console.error('Failed to parse API response:', response.choices[0].message.content);
            console.error('Parse error:', parseError);
            throw new Error('Invalid JSON response from API');
        }
    } catch (error) {
        console.error('Error in extractReceiptData:', error);
        throw new Error(`Error extracting receipt data: ${error.message}`);
    }
}

/**
 * Saves receipt data to the database
 * @param {Object} receiptData - Receipt data object
 * @returns {Promise<void>}
 */
function saveReceiptToDatabase(receiptData) {
    return new Promise((resolve, reject) => {
        // Skip database save if DB_HOST is not configured
        if (!db) {
            console.log('Database connection not configured, skipping save');
            resolve();
            return;
        }

        const query = `INSERT INTO receipts (
            date, merchant, amount, description
        ) VALUES (?, ?, ?, ?)`;

        db.query(query, [
            receiptData.date,
            receiptData.merchant,
            receiptData.amount,
            receiptData.description
        ], (err) => {
            if (err) {
                reject(new Error(`Error saving receipt: ${err.message}`));
                return;
            }
            console.log('Receipt saved successfully');
            resolve();
        });
    });
}

/**
 * Main function to process a receipt
 * @param {string} imagePath - Path to the receipt image
 * @returns {Promise<Object>} - Processed receipt data
 */
async function processReceipt(imagePath) {
    try {
        // Step 1: Extract data from the image
        const extractedData = await extractReceiptData(imagePath);

        // Step 2: Save data to the database
        await saveReceiptToDatabase(extractedData);
        
        // Return the extracted data
        return extractedData;
    } catch (error) {
        throw error;
    }
}

module.exports = {
    processReceipt,
    extractReceiptData,
    saveReceiptToDatabase
};
