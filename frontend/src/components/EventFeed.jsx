 import React from "react";
import { motion } from "framer-motion";
import { getEvents } from "../services/api";

export default function EventFeed({ events }) {
  return (
    <div className="p-6 bg-neutral-900 rounded-2xl shadow-xl border border-neutral-800 h-full flex flex-col">
      <h2 className="text-xl font-bold text-white mb-4 tracking-wide">
        Event Feed
      </h2>

      <div className="space-y-4 overflow-y-auto pr-2">
        {events.map((ev, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -15 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.05 }}
            className="p-4 bg-neutral-800/40 rounded-xl border border-neutral-700/50 hover:bg-neutral-800/60 transition"
          >
            <div className="flex justify-between text-sm text-gray-400 mb-1">
              <span className="font-mono text-teal-300">{ev.ip}</span>
              <span>{ev.timestamp}</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-gray-200 font-light">
                {ev.event} on port <span className="font-mono">{ev.port}</span>
              </span>

              <span className="px-2 py-1 rounded-lg text-xs bg-indigo-600/20 text-indigo-300 border border-indigo-600/30">
                {ev.event}
              </span>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
