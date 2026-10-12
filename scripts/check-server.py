import concurrent.futures
import socket

HOST = "179.198.111.247"


def check(port):
    try:
        with socket.create_connection((HOST, port), timeout=5):
            return f"{HOST}:{port}: TCP reachable"
    except OSError as error:
        return f"{HOST}:{port}: {error}"


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(check, [21115, 21116, 21117]):
            print(result)
