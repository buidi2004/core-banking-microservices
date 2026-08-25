package com.fintech.wallet.infrastructure.security;

import java.io.Serializable;
import java.util.Map;

public class CachedResponse implements Serializable {
    private int status;
    private String contentType;
    private Map<String, String> headers;
    private byte[] body;

    public CachedResponse() {}

    public CachedResponse(int status, String contentType, Map<String, String> headers, byte[] body) {
        this.status = status;
        this.contentType = contentType;
        this.headers = headers;
        this.body = body;
    }

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

    public void setHeaders(Map<String, String> headers) {
        this.headers = headers;
    }

    public byte[] getBody() {
        return body;
    }

    public void setBody(byte[] body) {
        this.body = body;
    }
}
