export const getMaxMinPrice = (seats: { price: number }[]) => {
  var max = seats[0].price;
  var min = seats[0].price;
  for (let i = 1; i < seats.length; i++) {
    max = Math.max(max, seats[i].price);
    min = Math.min(min, seats[i].price);
  }
  return {
    min: min,
    max: max,
  };
};
