package com.fintech.ledger.application.kafka;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Khớp KafkaEventEnvelope<T> dùng chung theo đặc tả:
 * { eventId, traceId, timestamp, producerService, payload }
 * Hỗ trợ cả envelope bọc chuẩn và JSON phẳng (flat payload) từ các nguồn Kafka khác nhau.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class KafkaEventEnvelope {

    private String eventId;
    private String traceId;
    private String timestamp;
    private String producerService;
    private String topic;
    private Map<String, Object> payload;
    private Map<String, Object> additionalProperties = new HashMap<>();

    public KafkaEventEnvelope() {
    }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getTraceId() { return traceId; }
    public void setTraceId(String traceId) { this.traceId = traceId; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }

    public String getProducerService() { return producerService; }
    public void setProducerService(String producerService) { this.producerService = producerService; }

    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }

    public Map<String, Object> getPayload() {
        if (payload != null) {
            return payload;
        }
        return additionalProperties.isEmpty() ? null : additionalProperties;
    }

    public void setPayload(Map<String, Object> payload) { this.payload = payload; }

    @JsonAnySetter
    public void setAdditionalProperty(String key, Object value) {
        if (this.additionalProperties == null) {
            this.additionalProperties = new HashMap<>();
        }
        this.additionalProperties.put(key, value);
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return additionalProperties;
    }

    public Instant timestampInstant() {
        if (timestamp == null || timestamp.isBlank()) {
            return Instant.now();
        }
        try {
            return Instant.parse(timestamp);
        } catch (Exception e) {
            try {
                long epoch = Long.parseLong(timestamp);
                return Instant.ofEpochMilli(epoch);
            } catch (Exception ex) {
                return Instant.now();
            }
        }
    }

    @Override
    public String toString() {
        return "KafkaEventEnvelope{eventId=" + eventId + ", traceId=" + traceId
                + ", producerService=" + producerService + "}";
    }
}
