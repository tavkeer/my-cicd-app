const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Health check — Jenkins/load balancers use this to verify app is alive
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'App is healthy' });
});

// A simple GET route
app.get('/api/greet', (req, res) => {
  res.json({ message: 'Hello from the CI/CD pipeline!' });
});

// A POST route to echo back data
app.post('/api/echo', (req, res) => {
  res.json({ received: req.body });
});


app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
