
const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Parse JSON bodies
app.use(express.json());

// Database connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'afripay',
  user: process.env.DB_USER || 'afripay',
  password: process.env.DB_PASSWORD || 'devpass123',
  max: 10,
  idleTimeoutMillis: 30000,
});

// Health check endpoint - used by load balancer and k8s
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (err) {
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: err.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Readiness probe - checks if app is ready to receive traffic
app.get('/ready', (req, res) => {
  const isReady = pool.totalCount > 0;
  if (isReady) {
    res.json({ status: 'ready', message: 'Application is ready' });
  } else {
    res.status(503).json({ status: 'not ready', message: 'Database not connected' });
  }
});

// Metrics endpoint for Prometheus scraping
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`
# HELP afripay_health_check Health check status
# TYPE afripay_health_check gauge
afripay_health_check 1

# HELP afripay_uptime_seconds Application uptime
# TYPE afripay_uptime_seconds counter
afripay_uptime_seconds ${process.uptime()}

# HELP afripay_db_pool_total Total database connections
# TYPE afripay_db_pool_total gauge
afripay_db_pool_total ${pool.totalCount}
  `);
});

// Mock payment endpoint for testing
app.post('/api/v1/payment', async (req, res) => {
  const { amount, phone, reference } = req.body;
  
  // Validation
  if (!amount || !phone) {
    return res.status(400).json({
      error: 'Missing required fields',
      required: ['amount', 'phone']
    });
  }

  // Simulate async processing
  const transactionId = `TXN${Date.now()}${Math.floor(Math.random() * 1000)}`;
  
  res.json({
    transaction_id: transactionId,
    status: 'success',
    message: 'Payment processed successfully',
    amount: amount,
    phone: phone,
    reference: reference || null,
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'AfriPay Health API',
    version: '1.0.0',
    endpoints: {
      health: 'GET /health',
      ready: 'GET /ready',
      metrics: 'GET /metrics',
      payment: 'POST /api/v1/payment'
    }
  });
});

// Start server
app.listen(port, () => {
  console.log(`AfriPay API listening on port ${port}`);
  console.log(`Health check: http://localhost:${port}/health`);
})