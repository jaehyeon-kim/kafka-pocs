package com.linuxacademy.ccdak.producer;

public class Main {

    public static void main(String[] args) {
        MemberSignupsProducer producer = new MemberSignupsProducer();
        producer.handleMemberSignup(1, "Summers, Buffy");
        producer.handleMemberSignup(2, "Rosenberg, Willow");
        producer.handleMemberSignup(3, "Maclay, Tara");
        producer.handleMemberSignup(4, "Giles, Rupert");
        producer.handleMemberSignup(5, "Harris, Alexander");
        producer.handleMemberSignup(6, "Chase, Cordelia");
        producer.tearDown();
    }

}
