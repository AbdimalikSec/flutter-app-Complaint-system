const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
require("dotenv").config();

const router = express.Router();

/**
 * OPTION A:
 * Students do NOT self-register.
 * Admin creates student accounts from admin panel.
 */

// Login (student or admin)
router.post("/login", async (req, res) => {
  try {
    const { studentId, password } = req.body;

    if (!studentId || !password) {
      return res.status(400).json({ message: "studentId & password required" });
    }

    const user = await User.findOne({ studentId: studentId.trim() });

    if (!user) return res.status(401).json({ message: "Invalid credentials" });
    if (!user.isActive) return res.status(403).json({ message: "Account disabled" });

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign(
      {
        userId: user._id.toString(),
        role: user.role,
        name: user.name,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.json({
      token,
      user: {
        id: user._id,
        role: user.role,
        name: user.name,
        studentId: user.studentId,
        department: user.department,
        classLevel: user.classLevel,
        isActive: user.isActive,
      },
    });
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: String(e) });
  }
});

module.exports = router;
