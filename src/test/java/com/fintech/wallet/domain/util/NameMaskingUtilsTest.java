package com.fintech.wallet.domain.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class NameMaskingUtilsTest {

    @Test
    void testMaskName_ThreeWords() {
        assertEquals("NGUYEN V** AN", NameMaskingUtils.maskName("Nguyen Van An"));
        assertEquals("TRAN T** MAI", NameMaskingUtils.maskName("TRAN THI MAI"));
    }

    @Test
    void testMaskName_FourWords() {
        assertEquals("LE T** V** PHUC", NameMaskingUtils.maskName("Le Thi Van Phuc"));
    }

    @Test
    void testMaskName_TwoWords() {
        assertEquals("V** AN", NameMaskingUtils.maskName("Van An"));
        assertEquals("N***** AN", NameMaskingUtils.maskName("Nguyen An"));
    }

    @Test
    void testMaskName_SingleWord() {
        assertEquals("A*", NameMaskingUtils.maskName("An"));
        assertEquals("DZ***", NameMaskingUtils.maskName("Dzung"));
    }

    @Test
    void testMaskName_NullOrEmpty() {
        assertEquals("NGƯỜI DÙNG VÍ", NameMaskingUtils.maskName(null));
        assertEquals("NGƯỜI DÙNG VÍ", NameMaskingUtils.maskName(""));
        assertEquals("NGƯỜI DÙNG VÍ", NameMaskingUtils.maskName("   "));
    }
}
