package com.linuxacademy.ccdak.clients;

import java.util.Properties;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

public class ProducerMain {

    public static void main(String[] args) {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
        props.put("acks", "all");
        
        Producer<String, String> producer = new KafkaProducer<>(props);
        
        for (int i = 0; i < 100; i++) {
            int partition = 0;
            if (i > 49) {
                partition = 1;
            }
            ProducerRecord record = new ProducerRecord<>("test_count", partition, "count", Integer.toString(i));
            producer.send(record, (RecordMetadata metadata, Exception e) -> {
                if (e != null) {
                    System.out.println("Error publishing message: " + e.getMessage());
                } else {
                    System.out.println("Published message: key=" + record.key() +
                            ", value=" + record.value() +
                            ", topic=" + metadata.topic() +
                            ", partition=" + metadata.partition() +
                            ", offset=" + metadata.offset());
                }
            });
        }
        
        producer.close();
    }

}
