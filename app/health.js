const mysql = require('mysql2/promise');

const checkDatabase = async (dbConfig) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.ping();
    await connection.end();
    return { status: 'healthy', message: 'Database connection successful' };
  } catch (error) {
    return { status: 'unhealthy', message: error.message };
  }
};

const healthCheck = async (dbConfig) => {
  const dbHealth = await checkDatabase(dbConfig);
  
  return {
    status: dbHealth.status === 'healthy' ? 'healthy' : 'unhealthy',
    timestamp: new Date().toISOString(),
    services: {
      database: dbHealth
    },
    uptime: process.uptime(),
    memory: process.memoryUsage()
  };
};

module.exports = { healthCheck, checkDatabase };