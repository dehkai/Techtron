const OpenAI = require('openai');
require('dotenv').config();

// Initialize OpenAI client with DashScope API key and base URL
const openai = new OpenAI({
  apiKey: process.env.QWEN_API_KEY,
  baseURL: process.env.QWEN_API_URL,
});

/**
 * Extracts date, total amount, and merchant name from a receipt image using Qwen-VL-Max.
 * @param {string} imageUrl - Publicly accessible image URL or base64 string.
 * @returns {Promise<Object>} - Parsed JSON result from Qwen.
 */
async function extractReceiptData(imageUrl) {
  try {
    console.log('Starting receipt data extraction...');
    
    // Validate API configuration
    if (!process.env.QWEN_API_KEY || !process.env.QWEN_API_URL) {
      console.error('API configuration missing. Please check your .env file.');
      throw new Error('API configuration missing (QWEN_API_KEY or QWEN_API_URL)');
    }
    
    // Log that we're about to make the API call
    console.log(`Making API call to ${process.env.QWEN_API_URL} with model qwen-vl-max`);
    
    const response = await openai.chat.completions.create({
        model: "qwen-vl-max",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: `Extract only the following fields from this receipt:
- Date of purchase
- Total amount (including tax)
- Merchant name
Format the result as JSON with keys: date, total_amount, merchant_name.` },
            { type: "image_url", image: { url: imageUrl } }
          ],
        },
      ],
    });

    // Log successful API response
    console.log('API call successful. Processing response...');
    
    const resultText = response.choices[0]?.message?.content;

    if (!resultText) {
      console.error('No content returned from API response:', response);
      throw new Error('No content returned from Qwen.');
    }

    console.log('Raw API response content:', resultText);

    // Parse the JSON output
    let parsedResult;
    try {
      parsedResult = JSON.parse(resultText);
      console.log('Successfully parsed JSON result:', parsedResult);
    } catch (err) {
      console.error('Failed to parse API response as JSON:', resultText);
      throw new Error(`Failed to parse Qwen response as JSON: ${resultText}`);
    }

    return parsedResult;

  } catch (error) {
    // Log the full error with stack trace
    console.error('Detailed error in extractReceiptData:', error);
    
    // If it's an API error, it might have more details in the response
    if (error.response) {
      console.error('API Error Response:', error.response.data);
    }
    
    throw new Error(`Failed to extract receipt data: ${error.message}`);
  }
}

module.exports = {
  extractReceiptData,
};