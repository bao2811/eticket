import { useRouter } from "next/router";
import React from "react";
import { useState } from "react";

export default function RegisterPage() {
  const router = useRouter();

  const [form, setForm] = useState({
    username: "",
    password: "",
    confirmPassword: "",
    email: "",
  });

  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const Validation = () => {
    console.log(form);
    if (form.password !== form.confirmPassword) {
      setErrors({ confirmPassword: "Mật khẩu không khớp!" });
      return false;
    }
    if (form.password.length < 6) {
      setErrors({ password: "Mật khẩu phải có ít nhất 6 ký tự!" });
      return false;
    }
    if (!form.email.includes("@")) {
      setErrors({ email: "Email không hợp lệ!" });
      return false;
    }

    if (!form.username) {
      setErrors({ username: "Tên đăng nhập không được để trống!" });
      return false;
    }
    return true;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target as HTMLInputElement;
    setForm({ ...form, [name]: value.trim() });
    Validation();
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!Validation()) {
      return;
    }

    const response = await fetch("http://localhost:8080/auth/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(form),
    });

    if (response.ok) {
      alert("Dang ky thanh cong!");
      router.push("/login");
    } else {
      alert("Dang ky that bai");
    }
  };

  return (
    <div
      className="p-4"
      style={{
        maxWidth: "400px",
        margin: "auto",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        border: "1px solid #ccc",
        borderRadius: "8px",
        padding: "16px",
      }}
    >
      <h1>Dang Ky Tai Khoan</h1>
      <div>
        <form onSubmit={handleSubmit}>
          <label htmlFor="username">Ten Dang Nhap:</label>
          <input
            type="text"
            id="username"
            name="username"
            onChange={handleChange}
            required
          />
          {errors.username && <p style={{ color: "red" }}>{errors.username}</p>}
          <br />
          <label htmlFor="password">Mat Khau:</label>
          <input
            type="password"
            id="password"
            name="password"
            onChange={handleChange}
            required
          />
          {errors.password && <p style={{ color: "red" }}>{errors.password}</p>}
          <br />
          <label htmlFor="confirmPassword">Xac Nhan Mat Khau:</label>
          <input
            type="password"
            id="confirmPassword"
            name="confirmPassword"
            onChange={handleChange}
            required
          />
          {errors.confirmPassword && (
            <p style={{ color: "red" }}>{errors.confirmPassword}</p>
          )}
          <br />
          <label htmlFor="email">Email:</label>
          <input
            type="email"
            id="email"
            name="email"
            onChange={handleChange}
            required
          />
          {errors.email && <p style={{ color: "red" }}>{errors.email}</p>}
          <br />
          <button type="submit">Dang Ky</button>
        </form>
      </div>
    </div>
  );
}
