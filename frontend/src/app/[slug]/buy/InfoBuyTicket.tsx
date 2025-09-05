"use client";

import { useState, useEffect } from "react";
// import { Button } from "antd";
import { useFormContext } from "react-hook-form";

async function Onepay(selectedSeats: any, slug: string, account: any) {
  const seats = {
    A1: selectedSeats.A1 || [],
    A2: selectedSeats.A2 || [],
    B1: selectedSeats.B1 || [],
    B2: selectedSeats.B2 || [],
    C1: selectedSeats.C1 || [],
    C2: selectedSeats.C2 || [],
  };

  const payload = {
    customerName: account?.username || "Khách hàng",
    customerEmail: account?.email || "khachhang@example.com",
    seats,
    totalAmount: (selectedSeats.Amount || 0) * 100000,
    orderTime: Date.now(),
    status: "PENDING",
  };

  const res = await fetch("http://localhost:8080/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!res.ok) throw new Error("Failed to create OnePay request");

  const data = await res.json();
  console.log(data);
  if (typeof window !== "undefined") {
    const a = JSON.stringify(data);
    localStorage.setItem("orderId", a);
    console.log(data);
  }

  window.location.href = `/${slug}/buy/confirm`;
}

export default function InfoBuyTicket({
  seats,
  slug,
}: {
  seats: any;
  slug: string;
}) {
  const { watch } = useFormContext();
  const [account, setAccount] = useState<any>(null);
  const selectedSeats = watch("seats");

  // Lấy token + fetch account khi client render
  useEffect(() => {
    const token =
      typeof window !== "undefined" ? localStorage.getItem("token") : null;
    if (!token) return;

    fetch("http://localhost:8080/auth/account", {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((res) => {
        if (!res.ok) throw new Error("Failed to fetch account");
        return res.json();
      })
      .then((data) => setAccount(data))
      .catch((err) => console.error(err));
  }, []);

  let Amount = 0;
  let ticketPrice = 0;

  const numberToString = ({ seat }: any) => {
    let a = "";
    if (seat) {
      Amount += seat.length;
      ticketPrice = seat.length * 100000;
      a = seat.map((s: number) => s.toString().padStart(2, "0")).join(", ");
    }
    return a;
  };

  return (
    <div className="p-4 border border-gray-300 rounded">
      <form>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <strong>Ghế</strong>
            <p>A1: {numberToString({ seat: selectedSeats.A1 })}</p>
            <p>A2: {numberToString({ seat: selectedSeats.A2 })}</p>
            <p>B1: {numberToString({ seat: selectedSeats.B1 })}</p>
            <p>B2: {numberToString({ seat: selectedSeats.B2 })}</p>
            <p>C1: {numberToString({ seat: selectedSeats.C1 })}</p>
            <p>C2: {numberToString({ seat: selectedSeats.C2 })}</p>
          </div>
          <div>
            <strong>Số lượng</strong>
            <p>{selectedSeats.amountA1}</p>
            <p>{selectedSeats.amountA2}</p>
            <p>{selectedSeats.amountB1}</p>
            <p>{selectedSeats.amountB2}</p>
            <p>{selectedSeats.amountC1}</p>
            <p>{selectedSeats.amountC2}</p>
          </div>
          <div>
            <strong>Thông tin thanh toán</strong>
            <p>Tổng số ghế: {Amount}</p>
            <p>
              Thành Tiền:{" "}
              {ticketPrice.toLocaleString("vi-VN", {
                style: "currency",
                currency: "VND",
              })}
            </p>
          </div>
          <div>
            <div
              className="mt-4"
              onClick={(e) => {
                e.preventDefault();
                Onepay(selectedSeats, slug, account);
              }}
            >
              Thanh toán
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
