"use client";

import { Button } from "antd";
import { useState } from "react";

const Onepay = async (orderId: any) => {
  const res = await fetch("http://localhost:8080/checkout/onepay", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ orderId }),
  });

  if (!res.ok) {
    throw new Error("Failed to create OnePay request");
  }

  return await res.json(); // chỉ trả về JSON
};

export default function InfoBuyTicket() {
  const rawOrderId =
    typeof window !== "undefined" ? localStorage.getItem("orderId") : null;
  const orderId = rawOrderId ? JSON.parse(rawOrderId) : null;
  console.log(orderId);
  const [paymentUrl, setPaymentUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handlePayment = async () => {
    try {
      const data = await Onepay(orderId);
      if (data.paymentUrl === "Error occurred") {
        setError("Error occurred while processing payment.");
        setPaymentUrl(null);
      } else {
        setPaymentUrl(data.paymentUrl);
        setError(null);
      }
    } catch (err) {
      console.error(err);
      setError("Failed to create OnePay request.");
      setPaymentUrl(null);
    }
  };

  const numberToString = ({ seat }: any) => {
    let a = "";
    if (seat) {
      a = seat.map((s: number) => s.toString().padStart(2, "0")).join(", ");
    }
    return a;
  };

  return (
    <div>
      <h1>Confirm Your Purchase</h1>

      <div>
        <p>A1: {numberToString({ seat: orderId.A1 })}</p>
        <p>A2: {numberToString({ seat: orderId.A2 })}</p>
        <p>B1: {numberToString({ seat: orderId.B1 })}</p>
        <p>B2: {numberToString({ seat: orderId.B2 })}</p>
        <p>C1: {numberToString({ seat: orderId.C1 })}</p>
        <p>C2: {numberToString({ seat: orderId.C2 })}</p>
      </div>

      <Button type="primary" onClick={handlePayment}>
        OK
      </Button>

      {error && <p style={{ color: "red" }}>{error}</p>}
      {paymentUrl && (
        <div>
          <a href={paymentUrl} target="_blank" rel="noopener noreferrer">
            Thanh toán
          </a>
        </div>
      )}
    </div>
  );
}
