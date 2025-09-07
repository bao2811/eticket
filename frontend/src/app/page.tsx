import Image from "next/image";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { Container } from "@/module/Container";
import { Slidebar } from "@/components/Slidebar";
import Account from "@/components/Account";
import Basket from "@/components/Basket";

export default function Home() {
  return (
    <div>
      <Container>
        <div className="px-5">
          <Account />
          {/* <Basket /> */}
          <Slidebar />
          <Header />
          <Footer />
        </div>
      </Container>
    </div>
  );
}
