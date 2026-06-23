import asyncio
import httpx
import sqlite3

API_URL = "http://localhost:3213/driver_man"

async def test_duplicate_registration():
    async with httpx.AsyncClient() as client:
        # Initial registration
        res1 = await client.post(f"{API_URL}/identity/register", json={
            "driver_id": "test_adv_1", "vehicle_type": "car"
        })
        # Duplicate registration
        res2 = await client.post(f"{API_URL}/identity/register", json={
            "driver_id": "test_adv_1", "vehicle_type": "truck"
        })
        print("Duplicate Registration Status:", res2.status_code)

async def test_sql_injection_payload():
    async with httpx.AsyncClient() as client:
        res = await client.post(f"{API_URL}/dispatch", json={
            "driver_id": "test_adv_2", "location": "'; DROP TABLE dispatches; --"
        })
        print("SQL Injection Dispatch Status:", res.status_code)

async def main():
    print("Starting Adversarial Validation...")
    try:
        await test_duplicate_registration()
        await test_sql_injection_payload()
    except Exception as e:
        print("Validation API call failed. Is server running?", e)
    print("Validation Complete.")

if __name__ == "__main__":
    asyncio.run(main())
