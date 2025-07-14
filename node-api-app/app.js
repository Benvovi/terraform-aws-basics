const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.status(200).send("App is running on AWS Fargate!");
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
