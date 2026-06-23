import asyncio
import httpx
import websockets
import json
import random

API_URL = "http://localhost:3213/driver_man"

async def simulate_driver(driver_id):
    async with httpx.AsyncClient() as client:
        try:
            res = await client.post(f"{API_URL}/identity/register", json={
                "driver_id": driver_id, "vehicle_type": "autonomous"
            })
            print(f"[{driver_id}] register:", res.status_code)
        except Exception as e:
            pass
            
        try:
            res = await client.post(f"{API_URL}/dispatch", json={
                "driver_id": driver_id, "location": f"Node-{random.randint(1,100)}"
            })
            print(f"[{driver_id}] dispatch:", res.status_code)
        except Exception as e:
            pass

async def telemetry_listener():
    try:
        async with websockets.connect("ws://localhost:3213/driver_man/telemetry") as websocket:
            print("Telemetry connected.")
            while True:
                msg = await websocket.recv()
                print("Telemetry:", msg)
    except Exception as e:
        print("Telemetry failed:", e)

async def main():
    listener = asyncio.create_task(telemetry_listener())
    await asyncio.sleep(1)
    tasks = [simulate_driver(f"driver-{i}") for i in range(50)]
    await asyncio.gather(*tasks)
    listener.cancel()

if __name__ == "__main__":
    asyncio.run(main())
