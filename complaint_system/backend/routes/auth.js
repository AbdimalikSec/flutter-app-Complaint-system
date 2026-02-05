const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
require("dotenv").config();

const router = express.Router();

/**
 * Login (student or admin)
 * - Students: studentId + password
 * - Admins: email + password
 * Client sends: { identifier, password }
 */
router.post("/login", async (req, res) => {
  try {
    const { identifier, password } = req.body;

    const id = String(identifier || "").trim();
    const pw = String(password || "");

    if (!id || !pw) {
      return res.status(400).json({ message: "identifier & password required" });
    }

    const user = await User.findOne({
      $or: [{ studentId: id }, { email: id.toLowerCase() }],
    });

    if (!user) return res.status(401).json({ message: "Invalid credentials" });
    if (!user.isActive) return res.status(403).json({ message: "Account disabled" });

    const ok = await bcrypt.compare(pw, user.passwordHash);
    if (!ok) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign(
      { userId: user._id.toString(), role: user.role, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.json({
      token,
      user: {
        id: user._id,
        role: user.role,
        name: user.name,
        studentId: user.studentId || null,
        email: user.email || null,
        department: user.department || null,
        classLevel: user.classLevel || null,
        isActive: user.isActive,
      },
    });
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: e.message });
  }
});

module.exports = router;
