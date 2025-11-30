import React from "react";
import { blockIp } from "../services/api.js";
import { motion } from "framer-motion";

export default function ThreatTable({ threats, onBlocked }) {
  const handleBlock = async (ip) => {
    await blockIp(ip);
    onBlocked(ip); // notify parent to remove/update the row if needed
  };

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full border border-gray-700">
        <thead className="bg-gray-800 text-white">
          <tr>
            <th className="px-4 py-2">IP</th>
            <th className="px-4 py-2">Score</th>
            <th className="px-4 py-2">First Seen</th>
            <th className="px-4 py-2">Last Seen</th>
            <th className="px-4 py-2">Attack Types</th>
            <th className="px-4 py-2">Actions</th>
          </tr>
        </thead>
        <tbody>
          {threats.map((threat) => (
            <motion.tr
              key={threat.ip}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="border-t border-gray-700"
            >
              <td className="px-4 py-2">{threat.ip}</td>
              <td className="px-4 py-2">{threat.score}</td>
              <td className="px-4 py-2">{threat.first_seen}</td>
              <td className="px-4 py-2">{threat.last_seen}</td>
              <td className="px-4 py-2">
                {threat.attack_types.map((type, i) => (
                  <span key={i} className="bg-red-500 text-white px-2 py-1 rounded mr-1">
                    {type}
                  </span>
                ))}
              </td>
              <td className="px-4 py-2">
                <button
                  onClick={() => handleBlock(threat.ip)}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded"
                >
                  Block
                </button>
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
