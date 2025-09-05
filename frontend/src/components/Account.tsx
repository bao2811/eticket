"use client";

import AccountDropdown from "./AccountDropdown";
import React, { useEffect, useState } from "react";

export interface Account {
  username: string;
  email: string;
  phone?: string;
  address?: string;
  // thêm các trường khác nếu cần
}

export default function Account() {
  const [account, setAccount] = useState<Account | null>(null);
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    const storedToken = localStorage.getItem("token");
    setToken(storedToken);

    if (storedToken) {
      const fetchAccount = async () => {
        try {
          const res = await fetch("http://localhost:8080/auth/account", {
            headers: {
              Authorization: `Bearer ${storedToken}`,
            },
          });

          if (!res.ok) {
            throw new Error(`HTTP error! status: ${res.status}`);
          }

          const data: Account = await res.json();
          setAccount(data);
        } catch (error) {
          console.error("Failed to fetch account:", error);
        }
      };

      fetchAccount();
    }
  }, []);

  return (
    <AccountDropdown
      account={account}
      setAccount={setAccount}
      setToken={setToken}
    />
  );
}
