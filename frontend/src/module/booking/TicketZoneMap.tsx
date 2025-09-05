import { useState } from "react";

export default function TicketZoneMap(props: any) {
  const { seats } = props;
  const [selectedZone, setSelectedZone] = useState<any>(null);
  const [tooltip, setTooltip] = useState("");

  const handleZoneClick = (zone: any) => {
    if (zone.status !== "booked") {
      setSelectedZone(zone);
    }
  };

  return (
    <div className="relative w-full h-[600px]">
      <svg
        width="100%"
        height="100%"
        viewBox="0 0 400 600"
        className="border shadow-lg bg-white"
      >
        {seats.map((zone: any) => (
          <polygon
            key={zone.id}
            points={zone.points}
            fill={
              zone.status === "out"
                ? "#adb5bd"
                : selectedZone?.id === zone.id
                ? "#ffc107"
                : zone.color
            }
            stroke="#000"
            strokeWidth="1"
            onClick={() => handleZoneClick(zone)}
            onMouseEnter={() =>
              setTooltip(`${zone.name} - ${zone.price.toLocaleString()} VND`)
            }
            onMouseLeave={() => setTooltip("")}
          >
            <title>{`${zone.name} - ${zone.price.toLocaleString()} VND`}</title>
          </polygon>
        ))}
      </svg>

      {tooltip && (
        <div className="absolute bottom-2 left-2 bg-black text-white text-sm px-2 py-1 rounded shadow">
          {tooltip}
        </div>
      )}

      {selectedZone && (
        <div className="absolute right-2 top-2 bg-white border p-3 rounded shadow-md text-sm">
          <div>
            <strong>Khu vực:</strong> {selectedZone.name}
          </div>
          <div>
            <strong>Giá vé:</strong> {selectedZone.price.toLocaleString()} VND
          </div>
        </div>
      )}
    </div>
  );
}
