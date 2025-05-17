require('dotenv').config();
const app = require('./app');
const { pool } = require('./models/db');
const convertJsonRoutes = require('./routes/convertJsonRoutes');

const PORT = process.env.PORT || 3000;

// // Test database connection
// pool.connect((err, client, release) => {
//   if (err) {
//     console.error('Error connecting to the database:', err.stack);
//   } else {
//     console.log('Successfully connected to database');
//     release();
//   }
// });

app.use('/api/convertJson', convertJsonRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
}); 