const mongoose = require('mongoose');

async function test() {
  try {
    await mongoose.connect('mongodb://127.0.0.1:27017/notes_app?directConnection=true');
    console.log('DIRECT_SUCCESS');
    process.exit(0);
  } catch (err) {
    console.error('DIRECT_FAIL', err.message);
    process.exit(1);
  }
}

test();

