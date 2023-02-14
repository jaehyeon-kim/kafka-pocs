from datetime import datetime

import faust

app = faust.App("tasks-demo", broker="kafka://localhost:9093")


@app.task
async def on_startup():
    print("A task executing on startup")


@app.timer(interval=10)
async def on_interval():
    print(f"A task executing on interval at {datetime.now()}")
