import Link from "antd/es/typography/Link";
import { useRouter } from "next/router";
import React, { useState } from "react";

export default function LoginPage() {
  const router = useRouter();
  const redirectUrl =
    typeof router.query.redirectUrl === "string"
      ? router.query.redirectUrl
      : "/";
  const [form, setForm] = useState({
    username: "",
    password: "",
  });
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setErrors({});
    const response = await fetch("http://localhost:8080/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(form),
    });
    if (response.ok) {
      const data = await response.json();
      localStorage.setItem("token", data.token);
      alert("Dang nhap thanh cong!");
      router.push(redirectUrl);
    } else {
      const errorData = await response.json();
      setErrors({ form: errorData.message || "Dang nhap that bai!" });
    }
  };

  return (
    <div
      className="p-4"
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        border: "1px solid #ccc",
        borderRadius: "8px",
        width: "400px",
        margin: "auto",
      }}
    >
      <h1 className="text-2xl font-bold">Dang Nhap</h1>
      <form
        onSubmit={handleSubmit}
        className="mt-4"
        style={{ width: "300px", margin: "auto" }}
      >
        <div className="mb-4">
          <label htmlFor="username" className="block mb-2">
            Ten Dang Nhap:
          </label>
          <input
            type="text"
            id="username"
            name="username"
            value={form.username}
            onChange={handleChange}
            className="border p-2 w-full"
            required
          />
        </div>
        <div className="mb-4">
          <label htmlFor="password" className="block mb-2">
            Mat Khau:
          </label>
          <input
            type="password"
            id="password"
            name="password"
            value={form.password}
            onChange={handleChange}
            className="border p-2 w-full"
            required
          />
        </div>
        {errors.form && <p className="text-red-500">{errors.form}</p>}
        <button
          type="submit"
          className="bg-blue-500 text-white px-4 py-2 rounded"
        >
          Dang Nhap
        </button>
      </form>
      <p className="mt-4">
        Chua co tai khoan?{" "}
        <Link href="/register" className="text-blue-500">
          Dang Ky
        </Link>
      </p>
    </div>
  );
}
