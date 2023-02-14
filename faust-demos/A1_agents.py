import faust

app = faust.App("agents-demo", broker="kafka://localhost:9093")

greetings_topic = app.topic("greetings", value_type=str, value_serializer="raw")


@app.agent(greetings_topic)
async def greetings_processor(stream):
    async for greeting in stream:
        print(f"Greeting is '{greeting}'")
