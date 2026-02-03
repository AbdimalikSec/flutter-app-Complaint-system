const express = require("express");
const bcrypt = require("bcrypt");
const User = require("../models/User");
const { auth, requireRole } = require("../middleware/auth");

const router = express.Router();

// Create student
router.post("/", auth, requireRole("admin"), async (req, res) => {
  try {
    const { studentId, name, department, classLevel, password } = req.body;

    if (!studentId || !name || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const exists = await User.findOne({ studentId: studentId.trim() });
    if (exists) return res.status(409).json({ message: "Student ID exists" });

    const passwordHash = await bcrypt.hash(password, 10);

    const student = await User.create({
      studentId: studentId.trim(),
      name: name.trim(),
      department: (department || "").trim(),
      classLevel: (classLevel || "").trim(),
      passwordHash,
      role: "student",
      isActive: true,
    });

    // Don't send passwordHash back
    const safe = {
      _id: student._id,
      studentId: student.studentId,
      name: student.name,
      department: student.department,
      classLevel: student.classLevel,
      role: student.role,
      isActive: student.isActive,
      createdAt: student.createdAt,
      updatedAt: student.updatedAt,
    };

    return res.status(201).json(safe);
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: String(e) });
  }
});

// List students
router.get("/", auth, requireRole("admin"), async (req, res) => {
  try {
    const users = await User.find({ role: "student" })
      .select("-passwordHash")
      .sort({ createdAt: -1 });

    return res.json(users);
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: String(e) });
  }
});

// Activate / Deactivate
router.put("/:id/toggle", auth, requireRole("admin"), async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-passwordHash");
    if (!user) return res.status(404).json({ message: "Not found" });

    user.isActive = !user.isActive;
    await user.save();

    return res.json(user);
  } catch (e) {
    return res.status(500).json({ message: "Server error", error: String(e) });
  }
});

module.exports = router;
