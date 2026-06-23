import sqlite3
import random
import datetime

DB_PATH = "/home/tehlappy/Desktop/Lilith/state/golem_diary.db"

def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create table for the flat delivery data
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS driver_man_deliveries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME,
        driver TEXT,
        distance REAL,
        payout REAL,
        restaurant TEXT
    )
    ''')

    drivers = ["The Driver Man", "Dave", "Alice", "Bob"]
    restaurants = [
        "The Train Wreck Bar & Grill",
        "Skagit River Brewery",
        "Hal's Drive-In",
        "Pacioni's Pizzeria",
        "Joy's Bakery",
        "Rachawadee Thai Cafe",
        "Bob's Burgers and Brew",
        "Liberty Bistro",
        "Billy's Cafe",
        "Il Granaio Authentic Italian"
    ]

    # Assume a weekend starting from recent Friday 17:00
    start_time = datetime.datetime(2026, 6, 19, 17, 0, 0)
    
    rows = []
    for _ in range(500):
        # random minute in a 48 hour weekend window
        offset = random.randint(0, 48 * 60)
        timestamp = start_time + datetime.timedelta(minutes=offset)
        driver = random.choice(drivers)
        # distance in km
        distance = round(random.uniform(1.0, 25.0), 2)
        # basic payout logic: $5 base + $1.5 per km + random surge $0-$10
        payout = round(5.0 + (distance * 1.5) + random.uniform(0.0, 10.0), 2)
        restaurant = random.choice(restaurants)
        
        rows.append((timestamp.strftime('%Y-%m-%d %H:%M:%S'), driver, distance, payout, restaurant))

    # sort by timestamp so it looks like chronological inserts
    rows.sort(key=lambda x: x[0])

    cursor.executemany('''
    INSERT INTO driver_man_deliveries (timestamp, driver, distance, payout, restaurant)
    VALUES (?, ?, ?, ?, ?)
    ''', rows)

    conn.commit()
    conn.close()
    print(f"Successfully seeded 500 rows of synthetic delivery data into {DB_PATH}")

if __name__ == "__main__":
    main()
