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
 * Determines transaction type based on amount format
 * @param {string} amount - Amount string with possible signs or indicators
 * @returns {Object} - {type: 'credit'|'debit', amount: number}
 */
function determineTransactionType(amount) {
    // Convert amount to string if it's a number
    const amountStr = amount?.toString() || '0';
    
    // Remove currency symbols and commas
    let cleanAmount = amountStr.replace(/[^0-9.-]/g, '');
    
    // Check for explicit credit/debit indicators
    if (amountStr.toLowerCase().includes('cr') || amountStr.toLowerCase().includes('credit')) {
        return { type: 'credit', amount: Math.abs(parseFloat(cleanAmount)) };
    }
    if (amountStr.toLowerCase().includes('dr') || amountStr.toLowerCase().includes('debit')) {
        return { type: 'debit', amount: Math.abs(parseFloat(cleanAmount)) };
    }
    
    // Check for +/- signs
    if (cleanAmount.startsWith('-')) {
        return { type: 'debit', amount: Math.abs(parseFloat(cleanAmount)) };
    }
    if (cleanAmount.startsWith('+')) {
        return { type: 'credit', amount: Math.abs(parseFloat(cleanAmount)) };
    }
    
    // If amount is in parentheses, it's a debit
    if (amountStr.includes('(') && amountStr.includes(')')) {
        return { type: 'debit', amount: Math.abs(parseFloat(cleanAmount)) };
    }
    
    // If no indicators found, preserve the original type from parsed data
    return { type: 'credit', amount: Math.abs(parseFloat(cleanAmount)) };
}

/**
 * Generates a detailed prompt for bank statement extraction
 * @returns {string} - Structured prompt for the model
 */
function generateExtractionPrompt() {
    return `Please analyze this bank statement image and extract transaction information. The statement may be in various formats:

1. Date Formats to Handle:
   - DD/MM/YYYY (e.g., 25/12/2023)
   - MM/DD/YYYY (e.g., 12/25/2023)
   - DD/MM/YY (e.g., 25/12/23)
   - MM/YY (e.g., 12/23)
   - YYYY-MM-DD (e.g., 2023-12-25)

2. Amount Formats to Handle:
   - Separate credit/debit columns
   - Amounts with +/- signs (e.g., +1000.00 or -500.00 or 1000.00+ or 500.00-)
   - Amounts with CR/DR indicators
   - Amounts with currency symbols and commas
   - Amounts in parentheses (e.g., (500.00))

3. For each transaction, identify:
   - Date (convert to YYYY-MM-DD format)
   - Transaction type (credit or debit)
   - Description (transaction details)
   - Amount (numeric value only)

4. Important guidelines:
   - Skip any header/footer information
   - Focus only on actual transactions
   - For MM/YY format, use the first day of the month
   - Remove all currency symbols and commas from amounts
   - Determine transaction type based on:
     * Explicit CR/DR indicators
     * +/- signs
     * Separate credit/debit columns
   - Preserve the exact transaction description text

5. Output format:
   Each transaction should be structured as:
   {
     "date": "YYYY-MM-DD",
     "type": "credit/debit",
     "description": "transaction details",
     "amount": numeric_value
   }

Please ensure high accuracy in the extraction and maintain the chronological order of transactions.`;
}

/**
 * Extracts bank statement data from an image file by calling Model Studio API
 * @param {string} imagePath - Path to the bank statement image
 * @returns {Promise<Array>} - Extracted transaction data
 */
async function extractBankStatementData(imagePath) {
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
                        text: 'You are a specialized bank statement parser. Extract all transactions and return them as a raw JSON array. Do not use markdown formatting, code blocks, or any other text formatting. Return only the JSON array.' 
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
            
            // Try to parse the content as JSON
            extractedData = JSON.parse(cleanContent);
            console.log('Parsed JSON data:', JSON.stringify(extractedData, null, 2));
            
            // If it's not an array, wrap it in an array
            if (!Array.isArray(extractedData)) {
                console.log('Response is not an array, wrapping in array');
                extractedData = [extractedData];
            }
            
            // Ensure all amounts are strings
            extractedData = extractedData.map(transaction => ({
                ...transaction,
                amount: transaction.amount?.toString() || '0'
            }));

            // Validate the data structure
            if (extractedData.length === 0) {
                console.log('Warning: No transactions extracted from the image');
            } else {
                console.log(`Successfully extracted ${extractedData.length} transactions`);
            }

            // Validate each transaction
            extractedData.forEach((transaction, index) => {
                if (!transaction.date || !transaction.description || !transaction.amount) {
                    console.log(`Warning: Transaction ${index} is missing required fields:`, transaction);
                }
            });

        } catch (parseError) {
            console.error('Failed to parse API response:', response.choices[0].message.content);
            console.error('Parse error:', parseError);
            throw new Error('Invalid JSON response from API');
        }

        // Post-process the extracted data
        const processedData = extractedData.map(transaction => {
            const { type, amount } = determineTransactionType(transaction.amount);
            return {
                ...transaction,
                date: standardizeDate(transaction.date),
                type: transaction.type || type, // Preserve original type if available
                amount: amount
            };
        });

        console.log('Final processed data:', JSON.stringify(processedData, null, 2));
        return processedData;
    } catch (error) {
        console.error('Error in extractBankStatementData:', error);
        throw new Error(`Error extracting bank statement data: ${error.message}`);
    }
}

/**
 * Transforms extracted data into structured JSON format
 * @param {Array} extractedData - Raw extracted data
 * @returns {string} - JSON string of transformed data
 */
function transformToJSON(extractedData) {
    // If extractedData is already an array, return it as is
    if (Array.isArray(extractedData)) {
        return JSON.stringify(extractedData);
    }

    const transactions = [];

    extractedData.forEach((item) => {
        // Skip items without required fields
        if (!item.date || (!item.credit && !item.debit) || !item.description || !item.amount) {
            return;
        }

        const transaction = {
            date: item.date,
            type: item.credit ? 'credit' : 'debit',
            description: item.description,
            amount: parseFloat(item.amount.replace(/[^0-9.-]/g, '')) || 0, // Remove non-numeric characters
        };
        transactions.push(transaction);
    });

    return JSON.stringify(transactions);
}

/**
 * Saves transactions to the database
 * @param {string} jsonString - JSON string of transactions
 * @returns {Promise<void>}
 */
function saveTransactionsToDatabase(jsonString) {
    return new Promise((resolve, reject) => {
        // Skip database save if DB_HOST is not configured
        if (!db) {
            console.log('Database connection not configured, skipping save');
            resolve();
            return;
        }

        const transactions = JSON.parse(jsonString);

        // Use parallel processing for better performance
        const promises = transactions.map((transaction) => {
            return new Promise((innerResolve, innerReject) => {
                const query = `INSERT INTO transactions (date, type, description, amount) VALUES (?, ?, ?, ?)`;
                db.query(query, 
                    [transaction.date, transaction.type, transaction.description, transaction.amount], 
                    (err, result) => {
                        if (err) {
                            innerReject(err);
                            return;
                        }
                        innerResolve(result);
                    }
                );
            });
        });

        Promise.all(promises)
            .then((results) => {
                console.log(`${results.length} transactions saved successfully`);
                resolve();
            })
            .catch((error) => {
                reject(new Error(`Error saving transactions: ${error.message}`));
            });
    });
}

/**
 * Main function to process a bank statement
 * @param {string} imagePath - Path to the bank statement image
 * @returns {Promise<void>}
 */
async function processBankStatement(imagePath) {
    try {
        // Step 1: Extract text from the image
        const extractedData = await extractBankStatementData(imagePath);

        // Step 2: Transform extracted data into JSON format
        const jsonString = transformToJSON(extractedData);

        // Step 3: Save JSON data to the database
        await saveTransactionsToDatabase(jsonString);
        
        // Return the extracted data directly
        return extractedData;
    } catch (error) {
        throw error;
    }
}

module.exports = {
    processBankStatement,
    extractBankStatementData,
    transformToJSON,
    saveTransactionsToDatabase
};