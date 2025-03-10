from confluent_kafka.admin import (
    AdminClient,
    NewTopic,
    ConfigResource,
    ConfigEntry,
    ResourceType,
    AlterConfigOpType,
)


def topic_exists(admin_client: AdminClient, topic_name: str):
    metadata = admin_client.list_topics()
    for t in iter(metadata.topics.values()):
        print(t)
        if t.topic == topic_name:
            return True
    return False


def create_topic(admin_client: AdminClient, topic_name: str):
    new_topic = NewTopic(topic_name, num_partitions=3, replication_factor=3)
    result_dict = admin_client.create_topics([new_topic])
    for topic, future in result_dict.items():
        try:
            future.result()
            print(f"Topic {topic} created")
        except Exception as e:
            print(f"Failed to create topic {topic}: {e}")


def get_max_size(admin_client: AdminClient, topic_name: str):
    resource = ConfigResource(ResourceType.TOPIC, topic_name)
    result_dict = admin_client.describe_configs([resource])
    config_entries = result_dict[resource].result()
    print(config_entries.keys())
    max_size = config_entries["max.message.bytes"]
    return max_size.value


def set_max_size(admin_client: AdminClient, topic_name: str, max_k: int):
    resource = ConfigResource(
        ResourceType.TOPIC,
        topic_name,
        incremental_configs=[
            ConfigEntry(
                "max.message.bytes",
                str(max_k * 1024),
                incremental_operation=AlterConfigOpType.SET,
            )
        ],
    )
    result_dict = admin_client.incremental_alter_configs([resource])
    return result_dict[resource].result()
