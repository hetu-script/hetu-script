import time


def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)


start = time.perf_counter()
result = fib(30)
elapsed = time.perf_counter() - start

print(f"fib(30) = {result}")
print(f"Python 运行时间: {elapsed * 1000:.3f} ms")
