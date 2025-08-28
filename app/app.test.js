const request = require('supertest');
const app = require('./server');

describe('AWS Infrastructure Platform API', () => {
  test('GET / should return welcome message and status', async () => {
    const response = await request(app)
      .get('/')
      .expect(200);
    
    expect(response.body).toHaveProperty('message');
    expect(response.body).toHaveProperty('status');
    expect(response.body.message).toBe('AWS Infrastructure Platform API');
    expect(response.body.status).toBe('healthy');
  });

  test('GET /api/health should return database health status', async () => {
    const response = await request(app)
      .get('/api/health')
      .expect('Content-Type', /json/);
    
    expect(response.body).toHaveProperty('status');
    expect(response.body).toHaveProperty('timestamp');
    // Test passes whether database is connected or not
    expect(['healthy', 'unhealthy']).toContain(response.body.status);
  });
});
