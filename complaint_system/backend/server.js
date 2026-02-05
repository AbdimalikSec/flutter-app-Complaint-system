const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/auth");
const complaintRoutes = require("./routes/complaints");
const adminUsersRoutes = require("./routes/adminUsers");

// ✅ ADD THIS: import User model so we can sync indexes
const User = require("./models/User");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => res.json({ message: "API running" }));

app.use("/api/auth", authRoutes);
app.use("/api/complaints", complaintRoutes);
app.use("/api/admin/users", adminUsersRoutes);

mongoose
  .connect(process.env.MONGO_URI)
  .then(async () => {
    console.log("✅ MongoDB connected");

    // ✅ ADD THIS: forces DB indexes to match your schema (fixes old unique index issues)
    await User.syncIndexes();
    console.log("✅ Indexes synced");

    const port = process.env.PORT || 5000;

    // ✅ OPTIONAL but recommended for emulator/real device access
    app.listen(port, "0.0.0.0", () =>
      console.log(`✅ Server running on port ${port}`)
    );
  })
  .catch((err) => console.error("❌ Mongo error:", err));
