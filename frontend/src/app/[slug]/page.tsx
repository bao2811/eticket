import { Container } from "@/module/Container";
import Image from "next/image";
import { Button, Tag } from "antd"; // Ensure you have Button component available
// Update the import path below to the correct location of Button component
import Account from "@/components/Account";

const BasicInfo = (props: any) => {
  const { data } = props;
  return (
    <div className="flex flex-col gap-4">
      {data.map((item: any) => (
        <div key={item.label} className="flex gap-2">
          <span className="font-semibold">{item.label}</span>
          <div className="text-gray-300">
            {item.value || "Chưa có thông tin"}
          </div>
        </div>
      ))}
    </div>
  );
};

function getMaxMinPrice(listZone: any[]) {
  const prices = listZone.map((zone) => zone.price);
  return {
    min: Math.min(...prices),
    max: Math.max(...prices),
  };
}

export default async function Page({ params }: { params: { slug: string } }) {
  const { slug } = await params;
  console.log("Slug:", slug);
  let price = { min: 0, max: 0 };

  // price = getMaxMinPrice(event?.tickets || []);

  const res = await fetch(
    `http://localhost:8080/events/title-event?idString=${slug}`
  );

  if (!res.ok) {
    throw new Error(`Network response was not ok. Status: ${res.status}`);
  }
  const event = await res.json();
  console.log("abc", event[0].id);

  const listZone = await fetch(
    `http://localhost:8080/zones/zone-event?id=${event[0].id}`
  );

  if (!listZone.ok) {
    throw new Error(`Network response was not ok. Status: ${listZone.status}`);
  }
  const zones = await listZone.json();
  console.log("Zones:", zones);

  price = getMaxMinPrice(zones);

  return (
    <section>
      <div className="bg-gray-700 w-full">
        <Container className="py-10">
          <Account />
          <div className="grid grid-cols-2 gap-5 py-10">
            <div>
              <div>
                <Image
                  src={event[0].image || ""}
                  alt={event[0].name || "Event Image"}
                  width={1600}
                  height={900}
                  className="w-full object-cover"
                />
              </div>
              <div>
                <Button
                  type="primary"
                  href={`/${slug}/buy`}
                  size="large"
                  className="w-full mt-1"
                >
                  Mua vé
                </Button>
              </div>
            </div>
            <div className="text-white">
              <div>
                <Tag>
                  {event[0] && event[0].status === "open"
                    ? "Đang mở bán"
                    : "Đã kết thúc"}
                </Tag>
                <h2 className="text-3xl font-bold mb-2">
                  {event[0].name || "Tên sự kiện"}
                </h2>
                <BasicInfo
                  data={[
                    {
                      label: "Thời gian :",
                      value: event[0].date || "Chưa có thông tin",
                    },
                    {
                      label: "Địa điểm :",
                      value: event[0].address || "Chưa có thông tin",
                    },
                    {
                      label: "Giá vé :",
                      value: price
                        ? `${price.min} - ${price.max} VND`
                        : "Chưa có thông tin",
                    },
                  ]}
                />
                <div>
                  {zones.map((zone: any) => (
                    <div key={zone.id} className="mt-2">
                      <Tag color="blue">{zone.name}</Tag>
                      <span className="text-gray-300">
                        price: {zone.price} VND
                      </span>
                      <span className="text-gray-300 ml-2">
                        ,color: {zone.color}
                      </span>
                      <span className="text-gray-300 ml-2">
                        ,points: {zone.points}
                      </span>
                      <span className="text-gray-300 ml-2">
                        ,quantity: {zone.quantity}
                      </span>
                      <span className="text-gray-300 ml-2">
                        ,enable: {zone.enable}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </Container>
      </div>
    </section>
  );
}
