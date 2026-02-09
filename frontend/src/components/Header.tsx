import { Menu } from "./Menu";

import { Container } from "../module/Container";

export const Header = () => {
  return (
    <div className="bg-gray-800">
      <nav className=" text-white p-4 w-full">
        <div className="container flex flex-col">
          <div className="font-bold px-5 w-full text-3xl pt-2">Events</div>
          <div className="pt-4 px-5">
            <ul className="flex space-x-6 overflow-x-auto scrollbar-hide-thin pb-4">
              <li className="whitespace-nowrap">
                <a href="/" className="hover:underline">
                  All
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/about" className="hover:underline">
                  Nhạc Sống
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Fan Meeting
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Thể Thao
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Điện Ảnh
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Anime
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Khóa học
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Sân khấu và nghệ thuật
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Hội thảo và cộng đồng
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Khóa học
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Nhạc sống
                </a>
              </li>
              <li className="flex-shrink-0">
                <a href="/events" className="hover:underline">
                  Live stream
                </a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </div>
  );
};
