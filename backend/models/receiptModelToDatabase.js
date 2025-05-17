const pool = require('./db');

/**
 * Creates a new receipt in the database.
 * @param {Object} receiptData - Data to save (date, total_amount, merchant_name).
 * @returns {Promise<Object>} - Created receipt object.
 */
async function createReceipt(receiptData) {
  try {
    const [result] = await pool.query(
      `INSERT INTO receipts (date, total_amount, merchant_name) VALUES (?, ?, ?)`,
      [receiptData.date, receiptData.total_amount, receiptData.merchant_name]
    );

    // Return the created receipt
    const createdReceipt = {
      id: result.insertId,
      ...receiptData,
    };

    return createdReceipt;
  } catch (error) {
    console.error('Error creating receipt:', error.message);
    throw new Error('Failed to create receipt.');
  }
}

module.exports = {
  createReceipt,
};