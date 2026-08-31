package com.fintech.wallet.infrastructure.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.RetryInterceptorBuilder;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.retry.interceptor.RetryOperationsInterceptor;

@Configuration
public class RabbitMqConfig {

    public static final String EXCHANGE_NAME = "wallet.transaction.events";
    
    // DLX
    public static final String DLX_NAME = "wallet.transaction.dlx";

    // Queues
    public static final String QUEUE_NOTIFICATION = "notification-queue";
    public static final String QUEUE_AUDIT_LOG = "audit-log-queue";
    public static final String QUEUE_RECEIPT = "receipt-generation-queue";
    public static final String QUEUE_LEDGER = "ledger-queue";

    // DLQs
    public static final String DLQ_NOTIFICATION = "notification-dlq";
    public static final String DLQ_AUDIT_LOG = "audit-log-dlq";
    public static final String DLQ_RECEIPT = "receipt-generation-dlq";
    public static final String DLQ_LEDGER = "ledger-dlq";

    @Bean
    public TopicExchange transactionExchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public DirectExchange deadLetterExchange() {
        return new DirectExchange(DLX_NAME);
    }

    // Builder for queues with DLX configured
    private Queue createQueueWithDlx(String queueName, String dlxName, String dlqRoutingKey) {
        return QueueBuilder.durable(queueName)
                .withArgument("x-dead-letter-exchange", dlxName)
                .withArgument("x-dead-letter-routing-key", dlqRoutingKey)
                .build();
    }

    // Queues
    @Bean
    public Queue notificationQueue() {
        return createQueueWithDlx(QUEUE_NOTIFICATION, DLX_NAME, DLQ_NOTIFICATION);
    }

    @Bean
    public Queue auditLogQueue() {
        return createQueueWithDlx(QUEUE_AUDIT_LOG, DLX_NAME, DLQ_AUDIT_LOG);
    }

    @Bean
    public Queue receiptQueue() {
        return createQueueWithDlx(QUEUE_RECEIPT, DLX_NAME, DLQ_RECEIPT);
    }

    @Bean
    public Queue ledgerQueue() {
        return createQueueWithDlx(QUEUE_LEDGER, DLX_NAME, DLQ_LEDGER);
    }

    // DLQs
    @Bean
    public Queue notificationDlq() {
        return QueueBuilder.durable(DLQ_NOTIFICATION).build();
    }

    @Bean
    public Queue auditLogDlq() {
        return QueueBuilder.durable(DLQ_AUDIT_LOG).build();
    }

    @Bean
    public Queue receiptDlq() {
        return QueueBuilder.durable(DLQ_RECEIPT).build();
    }

    @Bean
    public Queue ledgerDlq() {
        return QueueBuilder.durable(DLQ_LEDGER).build();
    }

    // Bindings (All transaction events fanout to these queues based on topic)
    @Bean
    public Binding notificationBinding(Queue notificationQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(notificationQueue).to(transactionExchange).with("transaction.#");
    }

    @Bean
    public Binding auditLogBinding(Queue auditLogQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(auditLogQueue).to(transactionExchange).with("transaction.#");
    }

    @Bean
    public Binding receiptBinding(Queue receiptQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(receiptQueue).to(transactionExchange).with("transaction.#");
    }

    @Bean
    public Binding ledgerBinding(Queue ledgerQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(ledgerQueue).to(transactionExchange).with("transaction.#");
    }

    // DLQ Bindings
    @Bean
    public Binding notificationDlqBinding(Queue notificationDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(notificationDlq).to(deadLetterExchange).with(DLQ_NOTIFICATION);
    }

    @Bean
    public Binding auditLogDlqBinding(Queue auditLogDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(auditLogDlq).to(deadLetterExchange).with(DLQ_AUDIT_LOG);
    }

    @Bean
    public Binding receiptDlqBinding(Queue receiptDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(receiptDlq).to(deadLetterExchange).with(DLQ_RECEIPT);
    }

    @Bean
    public Binding ledgerDlqBinding(Queue ledgerDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(ledgerDlq).to(deadLetterExchange).with(DLQ_LEDGER);
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter());
        return template;
    }
    
    @Bean
    public RetryOperationsInterceptor retryInterceptor() {
        return RetryInterceptorBuilder.stateless()
                .maxAttempts(3)
                .backOffOptions(1000, 2.0, 10000)
                .recoverer(new org.springframework.amqp.rabbit.retry.RejectAndDontRequeueRecoverer())
                .build();
    }
}
