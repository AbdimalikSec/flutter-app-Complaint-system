const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    studentId: {
      type: String,
      unique: true,
      sparse: true, // allows admin accounts without studentId
      trim: true,
    },

    name: { type: String, required: true, trim: true },

    department: { type: String, trim: true },
    classLevel: { type: String, trim: true },

    passwordHash: { type: String, required: true },

    role: {
      type: String,
      enum: ["student", "admin"],
      default: "student",
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);
