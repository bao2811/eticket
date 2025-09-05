"use client"; // nếu dùng Next.js 13+

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
// Update the import path below to the correct relative path where Account is defined.
// For example, if Account is defined in 'src/types/Account.ts', use:
import { Account } from "./Account";
// Adjust the path as needed based on your project structure.

interface AccountDropdownProps {
  account: Account | null;
  setAccount: (account: Account | null) => void;
  setToken: (token: string | null) => void;
}

export default function AccountDropdown({
  account,
  setAccount,
  setToken,
}: AccountDropdownProps) {
  const [open, setOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const router = useRouter();

  // Ẩn dropdown khi click ra ngoài
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div className="fixed top-4 right-4 z-50">
      <div className="relative" ref={menuRef}>
        {/* Avatar */}
        <img
          src="https://via.placeholder.com/40"
          alt="Avatar"
          className="w-10 h-10 rounded-full border cursor-pointer"
          onClick={() => setOpen(!open)}
        />

        {/* Dropdown */}
        {open && account && (
          <div className="absolute right-0 mt-2 w-64 bg-white rounded shadow-lg border p-4 space-y-2 z-50">
            <h2 className="text-lg font-semibold">Tài khoản của tôi</h2>
            <p>
              <strong>Username:</strong> {account?.username}
            </p>
            <p>
              <strong>Email:</strong> {account?.email}
            </p>
            <p>
              <strong>Phone:</strong> {account?.phone}
            </p>
            <p>
              <strong>Address:</strong> {account?.address}
            </p>

            <button
              onClick={() => {
                localStorage.removeItem("token");
                setToken(null);
                setAccount(null);
                setOpen(false);
                router.push("/login");
              }}
              className="mt-2 bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded w-full"
            >
              Đăng xuất
            </button>
          </div>
        )}

        {!account && (
          <div className="absolute right-0 mt-2 w-64 bg-white rounded shadow-lg border p-4 space-y-2 z-50">
            <button
              onClick={() => router.push("/login")}
              className="mt-2 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded w-full"
            >
              Đăng nhập
            </button>
            <button
              onClick={() => router.push("/register")}
              className="mt-2 bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded w-full"
            >
              Đăng ký
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
