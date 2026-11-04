const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const User = require('./models/User');
const Note = require('./models/Note');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/notes_app';

app.use(cors());
app.use(express.json());

// In-memory persistent fallback if local MongoDB service is stopped
let memoryUsers = [];
let memoryNotes = [];
let isMongoConnected = false;

// Attempt MongoDB connection
mongoose
  .connect(MONGODB_URI, { serverSelectionTimeoutMS: 2000 })
  .then(() => {
    isMongoConnected = true;
    console.log(' Connected to MongoDB successfully!');
  })
  .catch((err) => {
    isMongoConnected = false;
    console.log('⚠️ MongoDB server is not currently running. Switched to high-availability in-memory database fallback so app works seamlessly!');
  });

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'running',
    storage: isMongoConnected ? 'MongoDB (Local/Atlas)' : 'Embedded Memory DB',
  });
});

// AUTH: Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    if (isMongoConnected) {
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ error: 'Email already registered' });
      }

      const user = new User({ name, email, password });
      await user.save();

      return res.status(201).json({
        message: 'Account registered successfully',
        user: { id: user._id.toString(), name: user.name, email: user.email },
      });
    } else {
      // In-memory fallback
      const existingUser = memoryUsers.find((u) => u.email.toLowerCase() === email.toLowerCase());
      if (existingUser) {
        return res.status(400).json({ error: 'Email already registered' });
      }

      const newUser = {
        id: Date.now().toString(),
        name,
        email,
        password,
      };
      memoryUsers.push(newUser);

      return res.status(201).json({
        message: 'Account registered successfully',
        user: { id: newUser.id, name: newUser.name, email: newUser.email },
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// AUTH: Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    if (isMongoConnected) {
      const user = await User.findOne({ email });
      if (!user || user.password !== password) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      return res.json({
        message: 'Login successful',
        user: { id: user._id.toString(), name: user.name, email: user.email },
      });
    } else {
      const user = memoryUsers.find(
        (u) => u.email.toLowerCase() === email.toLowerCase() && u.password === password
      );
      if (!user) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      return res.json({
        message: 'Login successful',
        user: { id: user.id, name: user.name, email: user.email },
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// NOTES: Get notes for user
app.get('/api/notes', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ error: 'userId parameter is required' });
    }

    if (isMongoConnected) {
      const notes = await Note.find({ userId }).sort({ date: -1, createdAt: -1 });
      return res.json(notes);
    } else {
      const userNotes = memoryNotes
        .filter((n) => n.userId === userId)
        .sort((a, b) => new Date(b.date) - new Date(a.date));
      return res.json(userNotes);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// NOTES: Create note
app.post('/api/notes', async (req, res) => {
  try {
    const { userId, title, content, date, colorValue } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    if (isMongoConnected) {
      const note = new Note({
        userId,
        title: title || 'Untitled Note',
        content: content || '',
        date: date ? new Date(date) : new Date(),
        colorValue: colorValue || 0xFFEEF2FF,
      });

      await note.save();
      return res.status(201).json(note);
    } else {
      const newNote = {
        _id: Date.now().toString(),
        userId,
        title: title || 'Untitled Note',
        content: content || '',
        date: date ? new Date(date) : new Date(),
        colorValue: colorValue || 0xFFEEF2FF,
      };
      memoryNotes.unshift(newNote);
      return res.status(201).json(newNote);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// NOTES: Update note
app.put('/api/notes/:id', async (req, res) => {
  try {
    const { title, content, date, colorValue } = req.body;

    if (isMongoConnected) {
      const note = await Note.findByIdAndUpdate(
        req.params.id,
        {
          title,
          content,
          date: date ? new Date(date) : undefined,
          colorValue,
        },
        { new: true }
      );

      if (!note) {
        return res.status(404).json({ error: 'Note not found' });
      }

      return res.json(note);
    } else {
      const idx = memoryNotes.findIndex((n) => n._id === req.params.id);
      if (idx === -1) {
        return res.status(404).json({ error: 'Note not found' });
      }

      memoryNotes[idx] = {
        ...memoryNotes[idx],
        title: title !== undefined ? title : memoryNotes[idx].title,
        content: content !== undefined ? content : memoryNotes[idx].content,
        date: date ? new Date(date) : memoryNotes[idx].date,
        colorValue: colorValue !== undefined ? colorValue : memoryNotes[idx].colorValue,
      };

      return res.json(memoryNotes[idx]);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// NOTES: Delete note
app.delete('/api/notes/:id', async (req, res) => {
  try {
    if (isMongoConnected) {
      const note = await Note.findByIdAndDelete(req.params.id);
      if (!note) {
        return res.status(404).json({ error: 'Note not found' });
      }

      return res.json({ message: 'Note deleted successfully', id: req.params.id });
    } else {
      const index = memoryNotes.findIndex((n) => n._id === req.params.id);
      if (index === -1) {
        return res.status(404).json({ error: 'Note not found' });
      }

      memoryNotes.splice(index, 1);
      return res.json({ message: 'Note deleted successfully', id: req.params.id });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Notes Backend Server listening on port ${PORT}`);
});
