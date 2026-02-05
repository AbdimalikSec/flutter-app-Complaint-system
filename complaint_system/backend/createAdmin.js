const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
require("dotenv").config();
const User = require("./models/User");

async function createAdmin() {
  await mongoose.connect(process.env.MONGO_URI);

  const passwordHash = await bcrypt.hash("admin1515", 10);

  await User.create({
    name: "System Admin",
    email: "admin@gmail.com",
    passwordHash,
    role: "admin",
  });

  console.log(" Admin created");
  process.exit();
}

createAdmin();
