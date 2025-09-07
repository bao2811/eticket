"use client";

import { useEffect, useState } from "react";

export default function Basket() {
  const [data, setData] = useState(null);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) return;

    fetch("http://localhost:8080/auth/basket", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
    })
      .then((res) => res.json())
      .then((data) => setData(data))
      .catch((err) => console.error("Error fetching basket:", err));
  }, []);

  return (
    <div>
      <h1>Basket Component</h1>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
}
