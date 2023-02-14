import random

import faust

app = faust.App("producer-consumer-demo", broker="kafka://localhost:9093")

greetings_topic = app.topic("greetings", value_type=str, value_serializer="raw")


@app.timer(interval=5)
async def generate_greeting():
    prefix = random.choice(["Hi", "Hello", "Howdy"])
    recipient = random.choice(["Deepika", "Bob", "Jo"])
    await greetings_topic.send(value=f"{prefix} {recipient}")


@app.agent(greetings_topic)
async def process_greetings(stream):
    async for greeting in stream:
        print(f"Greeting is '{greeting}'")
