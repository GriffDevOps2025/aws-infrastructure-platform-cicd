const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 80;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database configuration from environment variables
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'webapp',
  port: process.env.DB_PORT || 3306
};

// Health check endpoint (required for ALB)
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    message: 'AWS Infrastructure Platform API',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Database connection test endpoint
app.get('/api/health', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.ping();
    await connection.end();
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Export app for testing
module.exports = app;

// Start server only if this file is run directly
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}