import React, { useState, useEffect } from "react";
import Login from "./components/Login.jsx";
import ThreatTable from "./components/ThreatTable.jsx";
import EventFeed from "./components/EventFeed.jsx";
import { getThreats, getEvents } from "./services/api.js";

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false);
  const [threats, setThreats] = useState([]);
  const [events, setEvents] = useState([]);

  useEffect(() => {
    if (!loggedIn) return;
    getThreats().then(setThreats);
    getEvents().then(setEvents);
  }, [loggedIn]);

  if (!loggedIn) return <Login onLogin={() => setLoggedIn(true)} />;
  

  return (
    <div className="min-h-screen bg-neutral-950 text-white p-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2">
        <ThreatTable threats={threats} />
      </div>
      <div>
        <EventFeed events={events} />
      </div>
    </div>
  );
}
