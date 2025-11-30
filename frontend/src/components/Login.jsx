import React, { useState } from "react";
import { motion } from "framer-motion";

export default function Login({ onLogin }) {
  const [password, setPassword] = useState("");

  const submit = (e) => {
    e.preventDefault();
    if (password === "admin") onLogin();
    else alert("Incorrect password");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-950">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="p-8 bg-neutral-900 border border-neutral-700 rounded-3xl shadow-2xl w-80"
      >
        <h1 className="text-2xl text-white font-bold mb-6 text-center tracking-wide">
          Threat Console Login
        </h1>

        <form onSubmit={submit} className="space-y-4">
          <input
            type="password"
            placeholder="Enter password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full p-3 rounded-xl bg-neutral-800 text-gray-200 border border-neutral-700 focus:border-teal-400 outline-none"
          />

          <button
            type="submit"
            className="w-full py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-semibold transition active:scale-95"
          >
            Login
          </button>
        </form>
      </motion.div>
    </div>
  );
}
