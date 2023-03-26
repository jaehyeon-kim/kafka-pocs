package com.linuxacademy.ccdak.consumer;

import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

/**
 *
 * @author will
 */
public class MemberSignupsConsumer {
    
    Consumer<Integer, String> consumer;
    
    public MemberSignupsConsumer() {
        Properties props = new Properties();
        props.setProperty("bootstrap.servers", "localhost:9092");
        props.setProperty("group.id", "group1");
        props.setProperty("enable.auto.commit", "false");
        props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.IntegerDeserializer");
        props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        
        consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Arrays.asList("test_topic1", "test_topic2"));
    }
    
    public void run() {
        
        while (true) {
            ConsumerRecords<Integer, String> records = consumer.poll(Duration.ofMillis(100));
            handleRecords(records);
        }
        
    }
    
    public void handleRecords(ConsumerRecords<Integer, String> records) {
        for (ConsumerRecord<Integer, String> record : records) {
            System.out.println("key=" + record.key() + ", value=" + record.value() + ", topic=" + record.topic() + ", partition=" + record.partition() + ", offset=" + record.offset());
        }
        consumer.commitSync();
    }
    
}
