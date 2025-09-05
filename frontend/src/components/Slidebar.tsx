"use client";
import { Carousel } from "react-responsive-carousel";
import "react-responsive-carousel/lib/styles/carousel.min.css";

export const Slidebar = () => {
  return (
    <>
      <Carousel
        autoPlay
        interval={2000}
        infiniteLoop
        showArrows={true}
        showThumbs={false}
        showStatus={false}
        className="mb-5"
      >
        <div>
          <img
            className="object-cover w-full"
            src="https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=1500&q=75"
            alt="Slide 1"
          />
        </div>
        <div>
          <img
            className="object-cover w-full"
            src="https://assets.cticket.vn/tix/uppoom-1st-fan-meeting-vietnam-my-stand-in-world-tour/2.thumbnail_1600x900.webp?w=1500&q=75"
            alt="Slide 2"
          />
        </div>
      </Carousel>
    </>
  );
};
