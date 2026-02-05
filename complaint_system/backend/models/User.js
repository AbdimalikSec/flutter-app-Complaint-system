const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    studentId: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },

    // Admins may have email. Students do not need it.
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
      default: undefined,
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

    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// ✅ Prevent OverwriteModelError
module.exports = mongoose.models.User || mongoose.model("User", userSchema);
