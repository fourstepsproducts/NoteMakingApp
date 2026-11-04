const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      default: 'Untitled Note',
      trim: true,
    },
    content: {
      type: String,
      default: '',
    },
    date: {
      type: Date,
      default: Date.now,
    },
    colorValue: {
      type: Number,
      default: 0xFFEEF2FF,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Note', noteSchema);

