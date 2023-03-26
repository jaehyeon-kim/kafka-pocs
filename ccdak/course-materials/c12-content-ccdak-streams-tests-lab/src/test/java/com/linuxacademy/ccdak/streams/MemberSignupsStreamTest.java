package com.linuxacademy.ccdak.streams;

import java.util.Properties;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.IntegerDeserializer;
import org.apache.kafka.common.serialization.IntegerSerializer;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.TopologyTestDriver;
import org.apache.kafka.streams.test.ConsumerRecordFactory;
import org.apache.kafka.streams.test.OutputVerifier;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class MemberSignupsStreamTest {
    
    MemberSignupsStream memberSignupsStream;
    TopologyTestDriver testDriver;
    
    @Before
    public void setUp() {
        memberSignupsStream = new MemberSignupsStream();
        Topology topology = memberSignupsStream.topology;
        
        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "test");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "dummy:1234");
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.Integer().getClass().getName());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
        testDriver = new TopologyTestDriver(topology, props);
    }
    
    @After
    public void tearDown() {
        testDriver.close();
    }
    
    @Test
    public void test_first_name() {
        // Verify that the stream accurately parses the first name from the value.
        ConsumerRecordFactory<Integer, String> factory = new ConsumerRecordFactory<>("member_signups", new IntegerSerializer(), new StringSerializer());
        ConsumerRecord<byte[], byte[]> record = factory.create("member_signups", 1, "Summers, Buffy");
        testDriver.pipeInput(record);
        
        ProducerRecord<Integer, String> outputRecord = testDriver.readOutput("member_signups_mail", new IntegerDeserializer(), new StringDeserializer());
        
        OutputVerifier.compareKeyValue(outputRecord, 1, "Buffy");
    }
    
    @Test
    public void test_unknown_name_filter() {
        // Verify that the stream filters out records with an empty name value.
        ConsumerRecordFactory<Integer, String> factory = new ConsumerRecordFactory<>("member_signups", new IntegerSerializer(), new StringSerializer());
        ConsumerRecord<byte[], byte[]> record = factory.create("member_signups", 1, "UNKNOWN");
        testDriver.pipeInput(record);
        
        ProducerRecord<Integer, String> outputRecord = testDriver.readOutput("member_signups_mail", new IntegerDeserializer(), new StringDeserializer());
        
        Assert.assertNull(outputRecord);
    }
    
    @Test
    public void test_empty_name_filter() {
        // Verify that the stream filters out records with an empty name value.
        ConsumerRecordFactory<Integer, String> factory = new ConsumerRecordFactory<>("member_signups", new IntegerSerializer(), new StringSerializer());
        ConsumerRecord<byte[], byte[]> record = factory.create("member_signups", 1, "");
        testDriver.pipeInput(record);
        
        ProducerRecord<Integer, String> outputRecord = testDriver.readOutput("member_signups_mail", new IntegerDeserializer(), new StringDeserializer());
        
        Assert.assertNull(outputRecord);
    }
    
}
