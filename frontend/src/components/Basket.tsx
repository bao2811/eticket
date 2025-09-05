"use client";

export default async function Basket() {
  const token = localStorage.getItem("token");

  const res = await fetch("http://localhost:8080/auth/basket", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
  });
  const data = await res.json();
  return (
    <div>
      <h1>Basket Component</h1>
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
}
