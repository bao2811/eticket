import { Container } from "@/module/Container";
import { useForm, FormProvider } from "react-hook-form";
import GetSelectSeat from "./GetSelectSeat";
import Both from "./Both";
import Account from "@/components/Account";

const listSeat = (seats: any[]) => {};

export default async function eventPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  const res = await fetch(`http://localhost:8080/seats/list/${slug}`);
  if (!res.ok) {
    throw new Error(`Network response was not ok. Status: ${res.status}`);
  }
  const seats = await res.json();

  seats.sort((a: any, b: any) => {
    if (a.name !== b.name) {
      return a.name.localeCompare(b.name);
    }
    return a.location - b.location;
  });

  console.log("Seats data:", seats);

  return (
    <>
      {/* <section>
        <Container>
          <Slotseatevent event={event} />
        </Container>
      </section> */}

      <section>
        <Container>
          <Account />
          <div className="text-center mb-6">
            <div className="text-gray-300 text-sm mb-1">CHỌN GHẾ</div>
            <div className="h-1 bg-white w-1/2 mx-auto"></div>
          </div>
          <Both seats={seats} slug={slug} />
        </Container>
      </section>
    </>
  );
}
