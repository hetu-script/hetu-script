function fib(n) {
  if (n <= 1) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

const start = performance.now();
const result = fib(30);
const elapsed = performance.now() - start;

console.log(`fib(30) = ${result}`);
console.log(`Node.js 运行时间: ${elapsed.toFixed(3)} ms`);
