package com.fintech.notification.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.config.RetryInterceptorBuilder;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.retry.RejectAndDontRequeueRecoverer;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.retry.interceptor.RetryOperationsInterceptor;

@Configuration
public class RabbitMqConfig {

    public static final String EXCHANGE_NAME = "wallet.transaction.events";
    public static final String DLX_NAME = "wallet.transaction.dlx";

    public static final String ROUTING_KEY = "transaction.#";

    public static final String QUEUE_NOTIFICATION = "notification-service-queue";
    public static final String DLQ_NOTIFICATION = "notification-service-dlq";

    @Bean
    public TopicExchange transactionExchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public DirectExchange deadLetterExchange() {
        return new DirectExchange(DLX_NAME);
    }

    @Bean
    public Queue notificationQueue() {
        return QueueBuilder.durable(QUEUE_NOTIFICATION)
                .withArgument("x-dead-letter-exchange", DLX_NAME)
                .withArgument("x-dead-letter-routing-key", DLQ_NOTIFICATION)
                .build();
    }

    @Bean
    public Queue notificationDlq() {
        return QueueBuilder.durable(DLQ_NOTIFICATION).build();
    }

    @Bean
    public Binding notificationBinding(Queue notificationQueue, TopicExchange transactionExchange) {
        return BindingBuilder.bind(notificationQueue).to(transactionExchange).with(ROUTING_KEY);
    }

    @Bean
    public Binding notificationDlqBinding(Queue notificationDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(notificationDlq).to(deadLetterExchange).with(DLQ_NOTIFICATION);
    }

    @Bean
    public MessageConverter jsonMessageConverter(ObjectMapper objectMapper) {
        ObjectMapper tolerantMapper = objectMapper.copy()
                .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
        return new Jackson2JsonMessageConverter(tolerantMapper);
    }

    @Bean
    public RetryOperationsInterceptor retryInterceptor() {
        return RetryInterceptorBuilder.stateless()
                .maxAttempts(3)
                .backOffOptions(1000, 2.0, 10000)
                .recoverer(new RejectAndDontRequeueRecoverer())
                .build();
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory,
            MessageConverter jsonMessageConverter,
            RetryOperationsInterceptor retryInterceptor) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(jsonMessageConverter);
        factory.setAdviceChain(retryInterceptor);
        return factory;
    }
}
