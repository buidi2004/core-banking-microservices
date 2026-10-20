package com.fintech.ledger.infrastructure.amqp;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.config.RetryInterceptorBuilder;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.support.converter.Jackson2JavaTypeMapper;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.retry.interceptor.RetryOperationsInterceptor;

import java.util.Map;

@Configuration
public class AmqpConfig {

    public static final String TRANSACTION_EXCHANGE = "wallet.transaction.events";
    public static final String DEAD_LETTER_EXCHANGE = "wallet.transaction.dlx";
    public static final String LEDGER_QUEUE = "ledger-queue";
    public static final String LEDGER_DLQ = "ledger-dlq";
    public static final String LEDGER_ROUTING_KEY = "transaction.#";

    @Bean
    public TopicExchange transactionExchange() {
        return new TopicExchange(TRANSACTION_EXCHANGE, true, false);
    }

    @Bean
    public DirectExchange deadLetterExchange() {
        return new DirectExchange(DEAD_LETTER_EXCHANGE, true, false);
    }

    @Bean
    public Queue ledgerQueue() {
        return QueueBuilder.durable(LEDGER_QUEUE)
                .withArgument("x-dead-letter-exchange", DEAD_LETTER_EXCHANGE)
                .withArgument("x-dead-letter-routing-key", LEDGER_DLQ)
                .build();
    }

    @Bean
    public Queue ledgerDlq() {
        return QueueBuilder.durable(LEDGER_DLQ).build();
    }

    @Bean
    public Binding ledgerBinding(Queue ledgerQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(ledgerQueue).to(transactionExchange).with(LEDGER_ROUTING_KEY);
    }

    @Bean
    public Binding ledgerDlqBinding(Queue ledgerDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(ledgerDlq).to(deadLetterExchange).with(LEDGER_DLQ);
    }

    @Bean
    public MessageConverter ledgerMessageConverter() {
        // Jackson decode an toàn cho event publish từ Monolith (TypeId header không có class tương ứng
        // trong ledger-service → map class com.fintech.wallet...TransactionEvent về DTO nội bộ)
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        objectMapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);

        org.springframework.amqp.support.converter.DefaultJackson2JavaTypeMapper typeMapper =
                new org.springframework.amqp.support.converter.DefaultJackson2JavaTypeMapper();
        typeMapper.setIdClassMapping(Map.of(
                "com.fintech.wallet.domain.model.TransactionEvent",
                com.fintech.ledger.application.dto.TransactionEventMessage.class
        ));
        typeMapper.setTrustedPackages("com.fintech.wallet", "com.fintech.ledger");
        typeMapper.setTypePrecedence(Jackson2JavaTypeMapper.TypePrecedence.TYPE_ID);

        Jackson2JsonMessageConverter converter = new Jackson2JsonMessageConverter(objectMapper);
        converter.setJavaTypeMapper(typeMapper);
        return converter;
    }

    @Bean
    public RetryOperationsInterceptor ledgerRetryInterceptor() {
        return RetryInterceptorBuilder.stateless()
                .maxAttempts(3)
                .backOffOptions(1000, 2.0, 10000)
                .recoverer(new org.springframework.amqp.rabbit.retry.RejectAndDontRequeueRecoverer())
                .build();
    }

    @Bean
    public SimpleRabbitListenerContainerFactory ledgerListenerContainerFactory(
            ConnectionFactory connectionFactory,
            MessageConverter ledgerMessageConverter,
            RetryOperationsInterceptor ledgerRetryInterceptor) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(ledgerMessageConverter);
        factory.setAdviceChain(ledgerRetryInterceptor);
        factory.setDefaultRequeueRejected(true);
        return factory;
    }
}
