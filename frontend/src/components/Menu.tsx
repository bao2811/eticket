"use client";

import { MenuProps } from "antd";
import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { useEffect } from "react";
type MenuItem = Required<MenuProps>["items"][number];

const items: MenuItem[] = [
  {
    label: "Tài khoản",
    key: "account",
  },
  {
    label: "Đăng xuất",
    key: "logout",
  },
];
export const Menu = () => {
  const [current, setCurrent] = useState("mail");
  const router = useRouter();

  const [eventList, setEventList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const response = await fetch("http://localhost:8080/events");
        console.log("Status:", response.status); // 👈 THÊM DÒNG NÀY

        if (!response.ok) {
          throw new Error(
            `Network response was not ok. Status: ${response.status}`
          );
        }
        const data = await response.json();
        console.log("Events data:", data); // 👈 THÊM DÒNG NÀY
        setEventList(data);
      } catch (error) {
        console.error("Failed to fetch events:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchEvents();
  }, []);

  const onClick: MenuProps["onClick"] = (e) => {
    console.log("click ", e);
    setCurrent(e.key);
  };
  return (
    <div>
      <div className="text-xl font-semibold mb-4 text-black mt-8 container mx-auto">
        Events a<br />
        a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
        <br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
        <br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
        <br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
        <br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
        <br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a<br />a
      </div>
      <div className="grid grid-cols-4 gap-4 container mx-auto mt-8">
        {eventList.map((event) => (
          <Link
            key={event.id}
            href={`/${event.id}`}
            className="p-4 border rounded-lg shadow-sm hover:shadow-md transition cursor-pointer block"
          >
            <Image
              src={event.image}
              alt={event.name}
              width={800}
              height={450}
              className="rounded-2xl"
            />
            <h3 className="text-lg font-bold">{event.name}</h3>
            <p className="text-sm text-gray-600">{event.date}</p>
            <p className="text-sm text-gray-600 mb-2">{event.description}</p>
            <p className="text-sm text-gray-600">Location: {event.location}</p>
          </Link>
        ))}
      </div>
    </div>
  );
};
