const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

async function query() {
  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection.client.db('sample_mflix');
  const user = await db.collection('users').findOne({ name: 'Test Note Saver' });
  console.log('User in sample_mflix:', user);
  await mongoose.disconnect();
}

query().catch(console.error);
