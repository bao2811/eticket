import { SlotInput } from "@/components/SlotInput";
import { Card, Tag } from "antd";
import { Controller } from "react-hook-form";

export const SeatList = (props: any) => {
  const { seats, control } = props;
  return (
    <>
      <Card title="Loại vé" extra="Số lượng">
        <div className="divide-gray-300 divide-y space-y-4">
          {seats.map((seat: any) => (
            <div key={seat.id} className="pb-4">
              <div>{seat.id}</div>
              <div className="flex justify-between">
                <div>{seat.price}</div>
                <div>
                  {seat.status === "available" ? (
                    <Controller
                      render={({ field }) => <SlotInput {...field} />}
                      control={control}
                      name={`seats.${seat.id}`}
                      defaultValue={0}
                    />
                  ) : (
                    <Tag>Hết vé</Tag>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </>
  );
};
