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
    <div className="min-h-screen w-full bg-gradient-to-br from-blue-100 via-purple-50 to-pink-100 ">
      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-full max-w-md flex items-center justify-center">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
            Đăng Ký Tài Khoản
          </h2>
        </div>

        <div className="bg-white py-8 px-6 shadow-2xl border border-purple-200 rounded-xl backdrop-blur-sm bg-white/90 mx-4 flex flex-col items-center">
          <form
            className="space-y-6 flex flex-col items-center"
            onSubmit={handleSubmit}
          >
            <div className="w-full text-center">
              <label
                htmlFor="username"
                className="block text-sm font-medium text-gray-700 text-center"
              >
                Tên đăng nhập
              </label>
              <div className="mt-1">
                <input
                  id="username"
                  name="username"
                  type="text"
                  required
                  onChange={handleChange}
                  placeholder="Nhập tên đăng nhập"
                  className="appearance-none block w-full px-3 py-3 border border-purple-200 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                />
              </div>
              {errors.username && (
                <p className="mt-2 text-sm text-red-600">{errors.username}</p>
              )}
            </div>

            <div className="w-full text-center">
              <label
                htmlFor="email"
                className="block text-sm font-medium text-gray-700 text-center"
              >
                Email
              </label>
              <div className="mt-1">
                <input
                  id="email"
                  name="email"
                  type="email"
                  required
                  onChange={handleChange}
                  placeholder="Nhập địa chỉ email"
                  className="appearance-none block w-full px-3 py-3 border border-purple-200 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                />
              </div>
              {errors.email && (
                <p className="mt-2 text-sm text-red-600">{errors.email}</p>
              )}
            </div>

            <div className="w-full text-center">
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-700 text-center"
              >
                Mật khẩu
              </label>
              <div className="mt-1">
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  onChange={handleChange}
                  placeholder="Nhập mật khẩu"
                  className="appearance-none block w-full px-3 py-3 border border-purple-200 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                />
              </div>
              {errors.password && (
                <p className="mt-2 text-sm text-red-600">{errors.password}</p>
              )}
            </div>

            <div className="w-full text-center">
              <label
                htmlFor="confirmPassword"
                className="block text-sm font-medium text-gray-700 text-center"
              >
                Xác nhận mật khẩu
              </label>
              <div className="mt-1">
                <input
                  id="confirmPassword"
                  name="confirmPassword"
                  type="password"
                  required
                  onChange={handleChange}
                  placeholder="Xác nhận lại mật khẩu"
                  className="appearance-none block w-full px-3 py-3 border border-purple-200 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                />
              </div>
              {errors.confirmPassword && (
                <p className="mt-2 text-sm text-red-600">
                  {errors.confirmPassword}
                </p>
              )}
            </div>

            <div className="w-full flex justify-center">
              <button
                type="submit"
                className="w-3/4 flex justify-center py-3 px-4 border border-transparent rounded-md shadow-lg text-sm font-medium text-white bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-300 ease-in-out transform hover:-translate-y-1"
              >
                Đăng ký
              </button>
            </div>
          </form>

          <div className="mt-8 flex flex-col items-center">
            <div className="relative w-full">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-white text-purple-600 font-medium">
                  Đã có tài khoản?
                </span>
              </div>
            </div>

            <div className="mt-6 flex justify-center">
              <button
                onClick={() => router.push("/login")}
                className="w-3/4 flex justify-center py-2 px-4 border border-purple-300 rounded-md shadow-sm bg-white/50 text-sm font-medium text-purple-700 hover:bg-purple-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-300"
              >
                Đăng nhập
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
