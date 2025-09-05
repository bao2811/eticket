function toSlug(str: string): string {
  return str
    .toLowerCase()
    .normalize("NFD") // chuyển về dạng tổ hợp để tách dấu tiếng Việt
    .replace(/[\u0300-\u036f]/g, "") // xóa dấu
    .replace(/[^a-z0-9\s-]/g, "") // xóa ký tự đặc biệt
    .trim()
    .replace(/\s+/g, "-") // thay khoảng trắng bằng dấu gạch ngang
    .replace(/-+/g, "-"); // gộp nhiều dấu gạch liền lại 1
}

// pages/blog/[slug].tsx
import { useRouter } from "next/router";

export default function BlogDetailPage() {
  const router = useRouter();
  const { slug } = router.query;

  return (
    <div className="p-4">
      <h1 className="text-2xl font-bold">Trang bài viết</h1>
      <p className="text-gray-600">Slug URL: {slug}</p>
    </div>
  );
}
