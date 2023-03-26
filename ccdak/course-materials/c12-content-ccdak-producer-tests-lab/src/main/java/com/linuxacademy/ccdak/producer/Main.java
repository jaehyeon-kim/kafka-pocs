package com.linuxacademy.ccdak.producer;

public class Main {

    public static void main(String[] args) {
        MemberSignupsProducer producer = new MemberSignupsProducer();
        producer.handleMemberSignup(1, "Summers, Buffy");
    }

}
