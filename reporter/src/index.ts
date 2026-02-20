// Express (web server)
import express from 'express';
import bodyParser from 'body-parser';

import { computerRouter } from './endpoints';

// Setup the express app
const app = express();

app.use(bodyParser.json());

app.use('/computer', computerRouter);

const PORT = process.env.PORT ?? 5000;
app.listen(PORT, () => console.log(`Reporter listening on port ${PORT}`));