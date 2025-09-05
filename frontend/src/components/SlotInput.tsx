"use client";

import { Button, InputNumber } from "antd";
import { useState } from "react";

export const SlotInput = (props: any) => {
  const { value = 0, onChange } = props;

  const increase = () => {
    onChange(value + 1);
  };
  const decrease = () => {
    if (value <= 0) {
      onChange(0);
    } else {
      onChange(value - 1);
    }
  };
  return (
    <div className="flex items-center gap-1">
      <Button onClick={decrease}>-</Button>
      <InputNumber value={value} />
      <Button onClick={increase}>+</Button>
    </div>
  );
};
