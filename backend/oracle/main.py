import time
import schedule
from workers.weather_worker import fetch_weather_data
from workers.market_worker import fetch_market_data
from workers.news_worker import scrape_agronomic_news

def start_oracle():
    print("==================================================")
    print(" Agrosul Global Data Oracle (Phase 2.5) Initialized")
    print(" Utilizing lightweight pure Python 'schedule' loop")
    print("==================================================")

    # In production these intervals might be 15 mins (weather), 1 hour (market), etc.
    # For testing, we can schedule them slightly faster.
    schedule.every(10).minutes.do(fetch_weather_data)
    schedule.every(1).hours.do(fetch_market_data)
    schedule.every(2).hours.do(scrape_agronomic_news)

    # Initial boot sequence (run immediately once)
    print("\n[Boot Sequence] Running initial fetch cycle...")
    fetch_weather_data()
    fetch_market_data()
    scrape_agronomic_news()

    print("\n[Boot Sequence] Initial fetch complete. Entering event loop...")
    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    start_oracle()
