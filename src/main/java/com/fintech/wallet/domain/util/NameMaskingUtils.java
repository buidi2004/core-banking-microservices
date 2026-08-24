package com.fintech.wallet.domain.util;

public final class NameMaskingUtils {

    private NameMaskingUtils() {}

    public static String maskName(String fullName) {
        if (fullName == null || fullName.trim().isEmpty()) {
            return "NGƯỜI DÙNG VÍ";
        }
        String[] parts = fullName.trim().toUpperCase().split("\\s+");
        if (parts.length == 1) {
            String single = parts[0];
            if (single.length() <= 2) {
                return single.charAt(0) + "*";
            }
            return single.substring(0, 2) + "*".repeat(Math.max(1, single.length() - 2));
        }
        if (parts.length == 2) {
            String first = parts[0];
            String last = parts[1];
            String maskedFirst = first.length() <= 2 ? first.charAt(0) + "*" : first.charAt(0) + "*".repeat(first.length() - 1);
            return maskedFirst + " " + last;
        }
        StringBuilder sb = new StringBuilder();
        sb.append(parts[0]);
        for (int i = 1; i < parts.length - 1; i++) {
            String middle = parts[i];
            sb.append(" ");
            sb.append(middle.charAt(0));
            sb.append("*".repeat(Math.max(1, middle.length() - 1)));
        }
        sb.append(" ");
        sb.append(parts[parts.length - 1]);
        return sb.toString();
    }
}
