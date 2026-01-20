const express = require("express");
const Complaint = require("../models/Complaint");
const { auth, requireRole } = require("../middleware/auth");

const router = express.Router();

// ===============================
// Student: create complaint
// ===============================
router.post("/", auth, requireRole("student"), async (req, res) => {
  try {
    const { category, title, description } = req.body;

    if (!category || !title || !description) {
      return res.status(400).json({
        message: "category, title, description required",
      });
    }

    const complaint = await Complaint.create({
      studentId: req.user.userId,
      category,
      title,
      description,
      status: "Pending",
      statusHistory: [
        { status: "Pending" }, // 🆕 initial timeline entry
      ],
    });

    return res.status(201).json(complaint);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: String(e),
    });
  }
});

// ===============================
// Student: list my complaints
// ===============================
router.get("/mine", auth, requireRole("student"), async (req, res) => {
  try {
    const list = await Complaint.find({
      studentId: req.user.userId,
    }).sort({ createdAt: -1 });

    return res.json(list);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: String(e),
    });
  }
});

// ===============================
// Admin: list all complaints
// ===============================
router.get("/", auth, requireRole("admin"), async (req, res) => {
  try {
    const list = await Complaint.find()
      .populate("studentId", "name email")
      .sort({ createdAt: -1 });

    return res.json(list);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: String(e),
    });
  }
});

// ===============================
// Admin: update status + adminNote
// ===============================
router.put("/:id/status", auth, requireRole("admin"), async (req, res) => {
  try {
    const { status, adminNote } = req.body;

    if (!status) {
      return res.status(400).json({ message: "status required" });
    }

    const complaint = await Complaint.findById(req.params.id);

    // Ensure timeline exists (for old complaints)
    if (!complaint.statusHistory || complaint.statusHistory.length === 0) {
      complaint.statusHistory = [{ status: complaint.status }];
    }

    // Update status
    complaint.status = status;
    complaint.adminNote = adminNote || "";

    // Push new timeline entry
    complaint.statusHistory.push({ status });

    await complaint.save();

    const populated = await complaint.populate("studentId", "name email");

    return res.json(populated);
  } catch (e) {
    return res.status(500).json({
      message: "Server error",
      error: String(e),
    });
  }
});

module.exports = router;
