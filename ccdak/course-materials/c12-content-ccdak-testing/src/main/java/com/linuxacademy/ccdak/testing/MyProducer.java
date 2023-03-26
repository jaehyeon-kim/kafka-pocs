package com.linuxacademy.ccdak.testing;

import java.util.Properties;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

/**
 *
 * @author will
 */
public class MyProducer {
    
    Producer<Integer, String> producer;
    
    public MyProducer() {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.IntegerSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
        props.put("acks", "all");
        
        producer = new KafkaProducer<>(props);
    }
    
    public void publishRecord(Integer key, String value) {
        ProducerRecord record = new ProducerRecord<>("test_topic", key, value);
        producer.send(record, (RecordMetadata recordMetadata, Exception e) -> {
            if (e != null) {
                System.err.println(e.getMessage());
            } else {
                System.out.println("key=" + record.key() + ", value=" + record.value());
            }
        });
    }
    
    public void tearDown() {
        producer.close();
    }
    
}
