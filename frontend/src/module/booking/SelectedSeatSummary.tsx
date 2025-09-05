import { Button, Card } from "antd";

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

export default SelectedSeatSummary;
