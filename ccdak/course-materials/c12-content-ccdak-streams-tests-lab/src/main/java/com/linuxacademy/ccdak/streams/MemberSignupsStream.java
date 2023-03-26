package com.linuxacademy.ccdak.streams;

import java.util.Properties;
import java.util.concurrent.CountDownLatch;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.KStream;

/**
 *
 * @author will
 */
public class MemberSignupsStream {
    
    final KafkaStreams streams;
    final Topology topology;
    
    public MemberSignupsStream() {
        // Set up the configuration.
        final Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "streams-example");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_CONFIG, 0);
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.Integer().getClass().getName());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
        
        // Get the source stream.
        final StreamsBuilder builder = new StreamsBuilder();
        final KStream<Integer, String> source = builder.stream("member_signups");
        
        source
            .filter((key, value) -> !value.equals("UNKNOWN"))
            .filter((key, value) -> value.indexOf(',') >= 0)
            .mapValues((value) -> {
                String firstName = value.substring(value.indexOf(',') + 1).trim();
                return firstName;
            })
            .to("member_signups_mail");
        
        topology = builder.build();
        
        streams = new KafkaStreams(topology, props);
    }
    
    
    
    public void run() {
        // Print the topology to the console.
        System.out.println(topology.describe());
        final CountDownLatch latch = new CountDownLatch(1);

        // Attach a shutdown handler to catch control-c and terminate the application gracefully.
        Runtime.getRuntime().addShutdownHook(new Thread("streams-shutdown-hook") {
            @Override
            public void run() {
                streams.close();
                latch.countDown();
            }
        });

        try {
            streams.start();
            latch.await();
        } catch (final Throwable e) {
            System.out.println(e.getMessage());
            System.exit(1);
        }
        System.exit(0);
    }
    
}
