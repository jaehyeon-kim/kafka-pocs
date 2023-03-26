package com.linuxacademy.ccdak.producer;

import java.util.Properties;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

/**
 *
 * @author will
 */
public class MemberSignupsProducer {
    
    Producer<Integer, String> producer;
    
    public MemberSignupsProducer() {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.IntegerSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
        props.put("acks", "all");
        
        producer = new KafkaProducer<>(props);
    }
    
    public void handleMemberSignup(Integer memberId, String name) {
        int partition;
        if (name.toUpperCase().charAt(0) <= 'M') {
            partition = 0;
        } else {
            partition = 1;
        }
        ProducerRecord record = new ProducerRecord<>("member_signups", partition, memberId, name.toUpperCase());
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
