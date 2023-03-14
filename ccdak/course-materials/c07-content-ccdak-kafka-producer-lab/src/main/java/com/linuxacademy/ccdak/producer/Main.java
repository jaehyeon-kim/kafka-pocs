package com.linuxacademy.ccdak.producer;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.Properties;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class Main {

    public static void main(String[] args) {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
        props.put("acks", "all");
        
        Producer<String, String> producer = new KafkaProducer<>(props);
        
        try {
            File file = new File(Main.class.getClassLoader().getResource("sample_transaction_log.txt").getFile());
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line; 
            while ((line = br.readLine()) != null) {
                String[] lineArray = line.split(":");
                String key = lineArray[0];
                String value = lineArray[1];
                producer.send(new ProducerRecord<>("inventory_purchases", key, value));
                if (key.equals("apples")) {
                    producer.send(new ProducerRecord<>("apple_purchases", key, value));
                }
            }
            br.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        
        producer.close();
    }

}
