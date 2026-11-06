package com.fintech.payment.domain.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class AmlCaseTest {
    @Test
    void exposesDistinctWorkflowStatuses() {
        assertNotNull(AmlCase.OPEN);
        assertNotNull(AmlCase.ASSIGNED);
        assertNotNull(AmlCase.INVESTIGATING);
        assertNotNull(AmlCase.FROZEN);
        assertNotNull(AmlCase.RELEASED);
        assertNotNull(AmlCase.CLOSED);
        assertNotEquals(AmlCase.OPEN, AmlCase.CLOSED);
    }
}
