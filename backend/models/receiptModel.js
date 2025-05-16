const { pool } = require('./db');

class ReceiptModel {
  static async create(receiptData) {
    const { user_id, merchant_name, amount, date, category, image_url } = receiptData;
    const query = `
      INSERT INTO receipts (user_id, merchant_name, amount, date, category, image_url)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
    const values = [user_id, merchant_name, amount, date, category, image_url];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }

  static async findByUserId(userId) {
    const query = 'SELECT * FROM receipts WHERE user_id = $1 ORDER BY date DESC';
    try {
      const result = await pool.query(query, [userId]);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }

  static async findById(id) {
    const query = 'SELECT * FROM receipts WHERE id = $1';
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }

  static async update(id, receiptData) {
    const { merchant_name, amount, date, category } = receiptData;
    const query = `
      UPDATE receipts
      SET merchant_name = $1, amount = $2, date = $3, category = $4, updated_at = NOW()
      WHERE id = $5
      RETURNING *
    `;
    const values = [merchant_name, amount, date, category, id];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }

  static async delete(id) {
    const query = 'DELETE FROM receipts WHERE id = $1 RETURNING *';
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }
}

module.exports = ReceiptModel; 