package com.linuxacademy.ccdak.consumer;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.MockConsumer;
import org.apache.kafka.clients.consumer.OffsetResetStrategy;
import org.apache.kafka.common.TopicPartition;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class MemberSignupsConsumerTest {
    
    MockConsumer<Integer, String> mockConsumer;
    MemberSignupsConsumer memberSignupsConsumer;
    
    // Contains data sent so System.out during the test.
    private ByteArrayOutputStream systemOutContent;
    private final PrintStream originalSystemOut = System.out;
    
    @Before
    public void setUp() {
        mockConsumer = new MockConsumer<>(OffsetResetStrategy.EARLIEST);
        memberSignupsConsumer = new MemberSignupsConsumer();
        memberSignupsConsumer.consumer = mockConsumer;
    }
    
    @Before
    public void setUpStreams() {
        systemOutContent = new ByteArrayOutputStream();
        System.setOut(new PrintStream(systemOutContent));
    }

    @After
    public void restoreStreams() {
        System.setOut(originalSystemOut);
    }
    
    @Test
    public void testHandleRecords_output() {
        // Verify that the testHandleRecords writes the correct data to System.out
        // A text fixture called systemOutContent has already been set up in this class to capture System.out data.
        String topic = "member_signups";
        ConsumerRecord<Integer, String> record = new ConsumerRecord<>(topic, 0, 1, 2, "ROSENBERG, WILLOW");
        Map<TopicPartition, List<ConsumerRecord<Integer, String>>> records = new LinkedHashMap<>();
        records.put(new TopicPartition(topic, 0), Arrays.asList(record));
        ConsumerRecords<Integer, String> consumerRecords = new ConsumerRecords<>(records);
        
        memberSignupsConsumer.handleRecords(consumerRecords);
        Assert.assertEquals("key=2, value=ROSENBERG, WILLOW, topic=member_signups, partition=0, offset=1\n", systemOutContent.toString());
    }
    
    @Test
    public void testHandleRecords_none() {
        // Verify that testHandleRecords behaves correctly when processing no records.
        // A text fixture called systemOutContent has already been set up in this class to capture System.out data.
        String topic = "member_signups";
        Map<TopicPartition, List<ConsumerRecord<Integer, String>>> records = new LinkedHashMap<>();
        records.put(new TopicPartition(topic, 0), Arrays.asList());
        ConsumerRecords<Integer, String> consumerRecords = new ConsumerRecords<>(records);
        
        memberSignupsConsumer.handleRecords(consumerRecords);
        Assert.assertEquals("", systemOutContent.toString());
    }
    
    @Test
    public void testHandleRecords_multiple() {
        // Verify that testHandleRecords behaves correctly when processing multiple records.
        // A text fixture called systemOutContent has already been set up in this class to capture System.out data.
        String topic = "member_signups";
        ConsumerRecord<Integer, String> record1 = new ConsumerRecord<>(topic, 0, 1, 2, "ROSENBERG, WILLOW");
        ConsumerRecord<Integer, String> record2 = new ConsumerRecord<>(topic, 3, 4, 5, "HARRIS, ALEXANDER");
        Map<TopicPartition, List<ConsumerRecord<Integer, String>>> records = new LinkedHashMap<>();
        records.put(new TopicPartition(topic, 0), Arrays.asList(record1, record2));
        ConsumerRecords<Integer, String> consumerRecords = new ConsumerRecords<>(records);
        
        memberSignupsConsumer.handleRecords(consumerRecords);
        Assert.assertEquals("key=2, value=ROSENBERG, WILLOW, topic=member_signups, partition=0, offset=1\nkey=5, value=HARRIS, ALEXANDER, topic=member_signups, partition=3, offset=4\n", systemOutContent.toString());
    }
    
}
