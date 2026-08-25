package com.fintech.wallet.presentation.response;

import java.util.Collections;
import java.util.List;

public class PageResponse<T> {
    private List<T> content;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;
    private boolean last;

    public PageResponse() {
        this.content = Collections.emptyList();
    }

    public PageResponse(List<T> content, int page, int size, long totalElements) {
        this.content = content != null ? content : Collections.emptyList();
        this.page = page;
        this.size = size > 0 ? size : 20;
        this.totalElements = totalElements;
        this.totalPages = this.size > 0 ? (int) Math.ceil((double) totalElements / this.size) : 0;
        this.last = page >= Math.max(0, this.totalPages - 1);
    }

    public static <T> PageResponse<T> of(List<T> content, int page, int size, long totalElements) {
        return new PageResponse<>(content, page, size, totalElements);
    }

    public List<T> getContent() {
        return content;
    }

    public void setContent(List<T> content) {
        this.content = content;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public int getSize() {
        return size;
    }

    public void setSize(int size) {
        this.size = size;
    }

    public long getTotalElements() {
        return totalElements;
    }

    public void setTotalElements(long totalElements) {
        this.totalElements = totalElements;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }

    public boolean isLast() {
        return last;
    }

    public void setLast(boolean last) {
        this.last = last;
    }
}
