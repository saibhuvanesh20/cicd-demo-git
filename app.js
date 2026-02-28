const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
// Main route - returns application info
// Installed nodejs on server
app.get('/', (req, res) => {
 res.json({
 message: 'CI/CD Pipeline Working!',
 version: process.env.APP_VERSION || '1.0.0',
 environment: process.env.NODE_ENV || 'production',
 timestamp: new Date().toISOString()
 });
});
// Health check route - used by AWS ALB
// Must return HTTP 200 for ALB to route traffic to this container
app.get('/health', (req, res) => {
 res.status(200).json({ status: 'healthy' });
});
app.listen(PORT, () => {
 console.log(`App running on port ${PORT}`);
});
