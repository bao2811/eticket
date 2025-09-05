"use client";

import { useForm, FormProvider } from "react-hook-form";
import GetSelectSeat from "./GetSelectSeat";
import InfoBuyTicket from "./InfoBuyTicket";

export default function Both({ seats, slug }: { seats: any; slug: string }) {
  const seat = useForm({
    defaultValues: {
      seats: {
        A1: [],
        A2: [],
        B1: [],
        B2: [],
        C1: [],
        C2: [],
        amountA1: 0,
        amountA2: 0,
        amountB1: 0,
        amountB2: 0,
        amountC1: 0,
        amountC2: 0,
        Amount: 0,
        Total: 0,
      },
    },
  });

  return (
    <div>
      <div className="grid grid-cols-2 gap-3">
        <FormProvider {...seat}>
          <div className="grid grid-cols-8 gap-1 justify-center text-sm mb-6">
            <GetSelectSeat seats={seats} />
          </div>

          <InfoBuyTicket seats={seats} slug={slug} />
        </FormProvider>
      </div>
    </div>
  );
}
