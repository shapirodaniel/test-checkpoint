const { add, subtract, multiply, divide } = require('./index');

describe('functions', () => {
  const x = 10,
    y = 20;

  test('add', () => {
    expect(add(x, y)).toBe(32);
  });

  test('subtract', () => {
    expect(subtract(x, y)).toBe(-10);
  });

  test('multiply', () => {
    expect(multiply(x, y)).toBe(200);
  });

  test('divide', () => {
    expect(divide(x, y)).toBe(0.5);
  });
});
