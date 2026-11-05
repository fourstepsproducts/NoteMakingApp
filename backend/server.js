const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const User = require('./models/User');
const Note = require('./models/Note');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/notes';

app.use(cors());
app.use(express.json());

// Helper function to safely mask MongoDB URI in logs
function getMaskedUri(uri) {
  try {
    return uri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@');
  } catch {
    return '[masked]';
  }
}

// Connection event listeners
mongoose.connection.on('connected', () => {
  const host = mongoose.connection.host || 'unknown';
  const dbName = mongoose.connection.name || 'notes_app';
  console.log(`✅ Connected to MongoDB successfully! Host: ${host}, Database: ${dbName}`);
});

mongoose.connection.on('error', (err) => {
  console.error('❌ MongoDB connection error:', err.message);
});

mongoose.connection.on('disconnected', () => {
  console.warn('⚠️ MongoDB connection lost/disconnected.');
});

// Attempt MongoDB connection with 15000ms timeout
console.log(`📡 Connecting to MongoDB: ${getMaskedUri(MONGODB_URI)}`);
mongoose
  .connect(MONGODB_URI, {
    dbName: 'notes_app',
    serverSelectionTimeoutMS: 15000,
  })
  .catch((err) => {
    console.error('❌ Initial MongoDB connection failed:', err.message);
  });

// Database availability middleware: rejects requests with 503 if DB is not connected
const requireDb = (req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({
      error: 'Database unavailable. Service is temporarily offline.',
    });
  }
  next();
};

// Health check endpoint (always accessible)
app.get('/', (req, res) => {
  const isConnected = mongoose.connection.readyState === 1;
  res.json({
    status: 'running',
    database: isConnected ? 'connected' : 'disconnected',
    host: isConnected ? mongoose.connection.host : null,
    dbName: isConnected ? mongoose.connection.name : null,
  });
});

// Apply database readiness check to all API routes
app.use('/api', requireDb);

// AUTH: Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const existingUser = await User.findOne({ email: cleanEmail });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const user = new User({
      name: name.trim(),
      email: cleanEmail,
      password,
    });

    await user.save();

    return res.status(201).json({
      message: 'Account registered successfully',
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    return res.status(500).json({ error: error.message });
  }
});

// AUTH: Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: cleanEmail });
    if (!user || user.password !== password) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    return res.json({
      message: 'Login successful',
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// NOTES: Get notes for user
app.get('/api/notes', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ error: 'userId parameter is required' });
    }

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid userId format' });
    }

    const notes = await Note.find({ userId }).sort({ date: -1, createdAt: -1 });
    return res.json(notes);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// NOTES: Create note
app.post('/api/notes', async (req, res) => {
  try {
    const { userId, title, content, date, colorValue } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid userId format' });
    }

    const note = new Note({
      userId,
      title: title || 'Untitled Note',
      content: content || '',
      date: date ? new Date(date) : new Date(),
      colorValue: colorValue !== undefined ? colorValue : 0xFFEEF2FF,
    });

    await note.save();
    return res.status(201).json(note);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// NOTES: Update note
app.put('/api/notes/:id', async (req, res) => {
  try {
    const { title, content, date, colorValue, userId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid note ID' });
    }

    const filter = { _id: req.params.id };
    if (userId && mongoose.Types.ObjectId.isValid(userId)) {
      filter.userId = userId;
    }

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (content !== undefined) updateData.content = content;
    if (date !== undefined) updateData.date = new Date(date);
    if (colorValue !== undefined) updateData.colorValue = colorValue;

    const note = await Note.findOneAndUpdate(filter, updateData, { new: true });
    if (!note) {
      return res.status(404).json({ error: 'Note not found' });
    }

    return res.json(note);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// NOTES: Delete note
app.delete('/api/notes/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid note ID' });
    }

    const note = await Note.findByIdAndDelete(req.params.id);
    if (!note) {
      return res.status(404).json({ error: 'Note not found' });
    }

    return res.json({ message: 'Note deleted successfully', id: req.params.id });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Notes Backend Server listening on port ${PORT}`);
});
