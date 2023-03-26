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
    
    Consumer<String, String> consumer;
    
    public MemberSignupsConsumer() {
        Properties props = new Properties();
        props.setProperty("bootstrap.servers", "zoo1:9092");
        props.setProperty("group.id", "group1");
        props.setProperty("enable.auto.commit", "false");
        props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        
        props.setProperty("fetch.min.bytes", "1024");
        props.setProperty("heartbeat.interval.ms", "2000");
        props.setProperty("auto.offset.reset", "earliest");
        
        consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Arrays.asList("member_signups"));
    }
    
    public void run() {
        
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
            handleRecords(records);
        }
        
    }
    
    public void handleRecords(ConsumerRecords<String, String> records) {
        for (ConsumerRecord<String, String> record : records) {
            System.out.println("key=" + record.key() + ", value=" + record.value() + ", topic=" + record.topic() + ", partition=" + record.partition() + ", offset=" + record.offset());
        }
        consumer.commitSync();
    }
    
}
