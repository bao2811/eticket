import { useFormContext } from "react-hook-form";
import { useState } from "react";

type SeatMap = {
  A1: number;
  A2: number;
  B1: number;
  B2: number;
  C1: number;
  C2: number;
};

export default function GetSelectSeat({ seats }: any) {
  const { watch, setValue } = useFormContext();

  // Declare seatState in the component scope so it can be accessed everywhere
  const [seatState, setSeatState] = useState(Array(49).fill(1));

  const map: SeatMap = {
    A1: 0,
    A2: 1,
    B1: 2,
    B2: 3,
    C1: 4,
    C2: 5,
  };

  const getSelectedSeats = (currentSeat: any, ind: number) => {
    setSeatState((prev) => {
      const newState = [...prev];
      // chỉ xử lý UI ở đây
      newState[ind] = newState[ind] === 0 ? 1 : 0;
      return newState;
    });

    // gọi setValue ngoài setSeatState
    const seat = [...(watch(`seats.${currentSeat.name}`) || [])];
    const amount = watch(`seats.amount${currentSeat.name}`) || 0;

    if (seatState[ind] === 0) {
      setValue(
        `seats.${currentSeat.name}`,
        seat.filter((loc) => loc !== currentSeat.location)
      );
      setValue(`seats.amount${currentSeat.name}`, Math.max(0, amount - 1));
    } else {
      setValue(`seats.${currentSeat.name}`, [...seat, currentSeat.location]);
      setValue(`seats.amount${currentSeat.name}`, amount + 1);
    }
  };

  const seatElements = [];
  const colors = [
    "bg-red-400",
    "bg-green-300",
    "bg-blue-300",
    "bg-yellow-300",
    "bg-purple-300",
    "bg-pink-300",
  ];
  // ví dụ
  const length = seats.length;
  var color = colors[0];
  for (let i = 0; i < length; ++i) {
    const currentSeat: {
      id: string;
      name: keyof SeatMap;
      location: number;
      status: string;
    } = seats[i];

    let ind = currentSeat.location + 8 * map[currentSeat.name];

    if (i > 0 && seats[i].name != seats[i - 1].name) {
      color = colors[Math.floor((i + 1) / 8)];
    }

    seatElements.push(
      <div
        key={currentSeat.id}
        className={`p-2 rounded ${
          currentSeat.status === "available" && seatState[ind]
            ? color
            : "bg-gray-300"
        } cursor-pointer`}
        onClick={() => {
          getSelectedSeats(currentSeat, ind);
        }}
      >
        {currentSeat.name}, {currentSeat.location}
      </div>
    );
  }

  return <>{seatElements}</>;
}
