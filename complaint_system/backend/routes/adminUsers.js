const express = require("express");
const bcrypt = require("bcrypt");
const User = require("../models/User");
const { auth, requireRole } = require("../middleware/auth");

const router = express.Router();

// ---------- helpers ----------
function isValidStudentId(s) {
  return typeof s === "string" && /^[A-Za-z0-9_-]{4,20}$/.test(s.trim());
}

function isValidName(name) {
  if (typeof name !== "string") return false;
  const n = name.trim();
  if (n.length < 2 || n.length > 60) return false;
  if (!/[A-Za-z]/.test(n)) return false;
  return /^[A-Za-z][A-Za-z\s.'-]*$/.test(n);
}

function isStrongEnoughPassword(pw) {
  return typeof pw === "string" && pw.length >= 6;
}

// ===============================
// Admin: Create student
// ===============================
router.post("/", auth, requireRole("admin"), async (req, res) => {
  try {
    const studentId = String(req.body.studentId || "").trim();
    const name = String(req.body.name || "").trim();
    const department = String(req.body.department || "").trim();
    const classLevel = String(req.body.classLevel || "").trim();
    const password = String(req.body.password || "");

    if (!studentId || !name || !password) {
      return res.status(400).json({
        message: "Student ID, Name and Password are required",
      });
    }

    if (!isValidStudentId(studentId)) {
      return res.status(400).json({
        message: "Invalid Student ID (use 4-20 chars: letters/numbers/_/-)",
      });
    }

    if (!isValidName(name)) {
      return res.status(400).json({
        message: "Invalid Name (must contain letters, not only numbers)",
      });
    }

    if (!isStrongEnoughPassword(password)) {
      return res.status(400).json({
        message: "Password must be at least 6 characters",
      });
    }

    if (!department) return res.status(400).json({ message: "Department is required" });
    if (!classLevel) return res.status(400).json({ message: "Class is required" });

    const exists = await User.findOne({ studentId });
    if (exists) return res.status(409).json({ message: "Student ID exists" });

    const passwordHash = await bcrypt.hash(password, 10);

    const student = await User.create({
      studentId,
      name,
      department,
      classLevel,
      passwordHash,
      role: "student",
      isActive: true,
    });

    return res.status(201).json({
      _id: student._id,
      studentId: student.studentId,
      name: student.name,
      department: student.department,
      classLevel: student.classLevel,
      role: student.role,
      isActive: student.isActive,
      createdAt: student.createdAt,
      updatedAt: student.updatedAt,
    });
  } catch (e) {
    if (e && e.code === 11000) {
      const key = Object.keys(e.keyPattern || {})[0] || "field";
      if (key === "studentId") return res.status(409).json({ message: "Student ID exists" });
      if (key === "email") return res.status(409).json({ message: "Email already exists" });
      return res.status(409).json({ message: `${key} already exists` });
    }

    return res.status(500).json({
      message: "Server error",
      error: e?.message ? e.message : String(e),
    });
  }
});

// ===============================
// Admin: List students
// ===============================
router.get("/", auth, requireRole("admin"), async (req, res) => {
  try {
    const users = await User.find({ role: "student" })
      .select("-passwordHash")
      .sort({ createdAt: -1 });

    return res.json(users);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: e?.message ? e.message : String(e),
    });
  }
});

// ===============================
// Admin: Activate / Deactivate
// ===============================
router.put("/:id/toggle", auth, requireRole("admin"), async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-passwordHash");
    if (!user) return res.status(404).json({ message: "Not found" });

    // Only students should be toggled here
    if (user.role !== "student") {
      return res.status(400).json({ message: "Only student accounts can be toggled" });
    }

    user.isActive = !user.isActive;
    await user.save();

    return res.json(user);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: e?.message ? e.message : String(e),
    });
  }
});

// ===============================
// ✅ Admin: Delete student
// ===============================
router.delete("/:id", auth, requireRole("admin"), async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("role name studentId");
    if (!user) return res.status(404).json({ message: "Not found" });

    // Protect admins from being deleted here
    if (user.role !== "student") {
      return res.status(400).json({ message: "Only student accounts can be deleted" });
    }

    await User.deleteOne({ _id: user._id });

    return res.json({
      message: "Student deleted",
      id: user._id,
      studentId: user.studentId,
      name: user.name,
    });
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: e?.message ? e.message : String(e),
    });
  }
});

module.exports = router;
