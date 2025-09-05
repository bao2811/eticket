"use client";
import { useForm } from "react-hook-form";
import { SeatList } from "./SeatList";
// import { SelectedSeatSummary } from "./SelectedSeatSummary";
import TicketZoneMap from "./TicketZoneMap";
import { Button, Card } from "antd";
export const Slotseatevent = (props: any) => {
  const { event } = props;
  const { seats } = event;

  const {
    register,
    handleSubmit,
    watch,
    control,
    formState: { errors },
  } = useForm({
    defaultValues: {
      seats: {
        CAT1: 0,
      } as any,
    },
  });

  const getSelectedSeats = () => {
    const values = watch();
    const seatKeys = Object.keys(values.seats);
    const selectedSeatKeys = seatKeys.filter(
      (seatKey: any) => values.seats[seatKey] > 0
    );
    const selectedSeats = seats
      .filter((seat: any) => selectedSeatKeys.includes(seat.id))
      .map((x: any) => ({
        ...x,
        quantity: values.seats[x.id],
      }));
    return selectedSeats;
  };

  return (
    <>
      <div className="grid grid-cols-2 gap-4 py-4 h-full">
        <TicketZoneMap seats={event.seats} />
        <div className="h-full flex flex-col">
          <SeatList seats={seats} control={control} />
          <div className="mt-4">
            <SelectedSeatSummary selectedSeats={getSelectedSeats()} />
          </div>
        </div>
      </div>
    </>
  );
};

// Export SelectedSeatSummary from this file
const SelectedSeatSummary = (props: any) => {
  const { selectedSeats } = props;
  return (
    <>
      <Card
        size="small"
        title="Vé đã chọn"
        actions={[
          <Button size="large" className="w-full mx-2">
            Tiếp tục
          </Button>,
        ]}
      >
        {selectedSeats.length > 0 ? (
          <div className="space-y-3">
            {selectedSeats.map((seat: any) => (
              <div className="rounded-lg border border-gray-200">
                <div className="flex justify-between gap-1 p-3">
                  <div className="flex flex-col gap-1">
                    <span className="text-xs">Hạng vé</span>
                    <div className="text-sm">{seat.name}</div>
                  </div>
                  <div className="flex flex-col gap-1">
                    <span className="text-xs">Số lượng</span>
                    <span className="text-sm">x{seat.quantity}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <>Bạn chưa chọn vé, vui lòng lựa chọn vé để thanh toán!</>
        )}
      </Card>
    </>
  );
};
