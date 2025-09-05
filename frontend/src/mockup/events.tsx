export const eventList = [
  {
    id: 1,
    name: "Event One",
    date: "2023-10-01",
    status: "open", // Example status field
    description: "This is the first event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "New York, NY", // Example additional fields
    slug: "event-one", // Example slug for URL
  },
  {
    id: 2,
    name: "Event Two",
    date: "2023-10-02",
    description: "This is the second event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "Los Angeles, CA", // Example additional fields
    slug: "event-two", // Example slug for URL
  },
  {
    id: 3,
    name: "Event Three",
    date: "2023-10-03",
    description: "This is the third event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "Chicago, IL",
    slug: "event-three", // Example slug for URL
  },
  {
    id: 4,
    name: "Event Four",
    date: "2023-10-04",
    description: "This is the fourth event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "Houston, TX",
    slug: "event-four", // Example slug for URL
  },
  {
    id: 5,
    name: "Event Five",
    date: "2023-10-05",
    description: "This is the fifth event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "Phoenix, AZ",
    slug: "event-five", // Example slug for URL
  },
  {
    id: 6,
    name: "Event Six",
    date: "2023-10-06",
    description: "This is the sixth event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "Philadelphia, PA",
    slug: "event-six", // Example slug for URL
  },
  {
    id: 7,
    name: "Event Seven",
    date: "2023-10-07",
    description: "This is the seventh event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "San Antonio, TX",
    slug: "event-seven", // Example slug for URL
  },
  {
    id: 8,
    name: "Event Eight",
    date: "2023-10-08",
    description: "This is the eighth event of the month.",
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    location: "San Diego, CA",
    slug: "event-eight", // Example slug for URL
  },
];

export const eventListWithDetails = [
  {
    id: 1,
    name: "Event One",
    date: "2023-10-01",
    status: "open",
    description: "This is the first event of the month.",
    type: "music",
    maxBuy: 5,
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    address: "New York, NY", // Example additional fields
    socials: {
      facebook: "https://fb.com/datbavip.computer",
      youtube: "https://youtube.com/sydexa",
      instagram: "https://instagram.com/datbavip.computer",
    },
    seats: [
      {
        id: "zone_cat1",
        name: "Khán đài CAT-1",
        price: 300000,
        color: "#d63384",
        points: "50,300 150,300 150,400 50,400",
        status: "available",
      },
      {
        id: "zone_cat2",
        name: "Khán đài CAT-2",
        price: 300000,
        color: "#d63384",
        points: "170,300 270,300 270,400 170,400",
        status: "available",
      },
      {
        id: "zone_vip1",
        name: "Khán đài VIP-2",
        price: 200000,
        color: "#6f42c1",
        points: "50,420 150,420 150,520 50,520",
        status: "out",
      },
      {
        id: "zone_svip",
        name: "Khán đài SVIP",
        price: 200000,
        color: "#6f42c1",
        points: "170,420 270,420 270,520 170,520",
        status: "available",
      },
    ],
    artists: [
      {
        name: "Sơn Tùng MTP",
        image: "",
      },
      {
        name: "Hà Trần",
        image: "",
      },
    ],
    hosts: [
      {
        name: "VPBank",
        image: "",
      },
      {
        name: "UET CodeCamp",
        image: "",
      },
    ],
  },
  {
    id: 2,
    name: "Event Two",
    date: "2023-10-02",
    status: "open",
    description: "This is the second event of the month.",
    type: "music",
    maxBuy: 5,
    image:
      "https://assets.cticket.vn/tix/2025-kim-jaejoong-asia-tour-concert-beauty-in-chaos-in-hanoi/Thumbnail_1600%20x%20900%20px.webp?w=2892&q=75",
    address: "Los Angeles, CA", // Example additional fields
    price: {
      min: 100,
      max: 500,
    },
    socials: {
      facebook: "https://fb.com/datbavip.computer",
      youtube: "https://youtube.com/sydexa",
      instagram: "https://instagram.com/datbavip.computer",
    },
    seats: [
      {
        id: "zone_cat1",
        name: "Khán đài CAT-1",
        price: 300000,
        color: "#d63384",
        points: "50,300 150,300 150,400 50,400",
        status: "available",
      },
      {
        id: "zone_cat2",
        name: "Khán đài CAT-2",
        price: 300000,
        color: "#d63384",
        points: "170,300 270,300 270,400 170,400",
        status: "available",
      },
      {
        id: "zone_vip1",
        name: "Khán đài VIP-2",
        price: 200000,
        color: "#6f42c1",
        points: "50,420 150,420 150,520 50,520",
        status: "out",
      },
      {
        id: "zone_svip",
        name: "Khán đài SVIP",
        price: 200000,
        color: "#6f42c1",
        points: "170,420 270,420 270,520 170,520",
        status: "available",
      },
    ],
    artists: [
      {
        name: "Sơn Tùng MTP",
        image: "",
      },
      {
        name: "Hà Trần",
        image: "",
      },
    ],
    hosts: [
      {
        name: "VPBank",
        image: "",
      },
      {
        name: "UET CodeCamp",
        image: "",
      },
    ],
  },
];
