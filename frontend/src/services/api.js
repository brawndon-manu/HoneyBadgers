// src/services/api.js

// Mock threats data
const mockThreats = [
  {
    ip: "192.168.1.10",
    score: 75,
    first_seen: "2025-11-01",
    last_seen: "2025-11-25",
    attack_types: ["DDoS", "SQL Injection"]
  },
  {
    ip: "10.0.0.5",
    score: 45,
    first_seen: "2025-11-05",
    last_seen: "2025-11-20",
    attack_types: ["Brute Force"]
  }
];

// Mock events data
const mockEvents = [
  { timestamp: "2025-11-25 12:00", ip: "192.168.1.10", port: 80, event: "DDoS attempt" },
  { timestamp: "2025-11-25 12:05", ip: "10.0.0.5", port: 22, event: "SSH login attempt" }
];

// Fetch threats (mock)
export const getThreats = async () => {
  return new Promise((resolve) => {
    setTimeout(() => resolve(mockThreats), 300); // simulate API delay
  });
};

// Fetch events (mock)
export const getEvents = async () => {
  return new Promise((resolve) => {
    setTimeout(() => resolve(mockEvents), 300);
  });
};

// Block an IP (mock)
export const blockIp = async (ip) => {
  return new Promise((resolve) => {
    console.log(`Blocking IP: ${ip}`);
    setTimeout(() => resolve({ success: true, ip }), 300);
  });
};
