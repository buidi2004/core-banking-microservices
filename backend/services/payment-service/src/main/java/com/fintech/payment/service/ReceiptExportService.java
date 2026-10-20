package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.repository.TransactionRepository;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.Rectangle;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.text.NumberFormat;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

@Slf4j
@Service
public class ReceiptExportService {

    private final TransactionRepository transactionRepository;
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm:ss dd/MM/yyyy")
            .withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
    private static final NumberFormat CURRENCY_FMT = NumberFormat.getNumberInstance(Locale.GERMANY);

    public ReceiptExportService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    @Transactional(readOnly = true)
    public byte[] generateReceiptPdf(String transactionId) {
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giao dịch: " + transactionId));

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 36, 36, 54, 54);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // Font styles
            Font brandFont = new Font(Font.HELVETICA, 16, Font.BOLD, new Color(16, 185, 129)); // Emerald Green
            Font titleFont = new Font(Font.HELVETICA, 14, Font.BOLD, new Color(30, 41, 59));
            Font labelFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(100, 116, 139));
            Font valueFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(15, 23, 42));
            Font amountFont = new Font(Font.HELVETICA, 20, Font.BOLD, new Color(16, 185, 129));
            Font footerFont = new Font(Font.HELVETICA, 8, Font.ITALIC, new Color(148, 163, 184));

            // Bank Name Header
            Paragraph brand = new Paragraph("NGAN HANG TMCP SEN HONG - SEN HONG BANK", brandFont);
            brand.setAlignment(Element.ALIGN_CENTER);
            document.add(brand);

            Paragraph hotline = new Paragraph("Hotline: 1900 8888 | Website: www.senhongbank.com.vn\n\n", footerFont);
            hotline.setAlignment(Element.ALIGN_CENTER);
            document.add(hotline);

            // Receipt Title
            Paragraph title = new Paragraph("BIEN LAI GIAO DICH DIEN TU / ELECTRONIC RECEIPT\n\n", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);

            // Amount Box
            Paragraph amountPar = new Paragraph(CURRENCY_FMT.format(tx.getAmount()) + " " + tx.getCurrency() + "\n", amountFont);
            amountPar.setAlignment(Element.ALIGN_CENTER);
            document.add(amountPar);

            Paragraph statusPar = new Paragraph("TRANG THAI: " + tx.getStatus() + "\n\n", labelFont);
            statusPar.setAlignment(Element.ALIGN_CENTER);
            document.add(statusPar);

            // Transaction Detail Table
            PdfPTable table = new PdfPTable(2);
            table.setWidthPercentage(90);
            table.setWidths(new float[]{35f, 65f});

            addRow(table, "Ma giao dich (TxCode):", tx.getTransactionCode() != null ? tx.getTransactionCode() : tx.getId(), labelFont, valueFont);
            addRow(table, "Thoi gian giao dich:", tx.getCreatedAt() != null ? TIME_FMT.format(tx.getCreatedAt()) : "N/A", labelFont, valueFont);
            addRow(table, "Loai giao dich:", tx.getType(), labelFont, valueFont);
            addRow(table, "Vi nguon (Source):", tx.getSourceWalletId() != null ? tx.getSourceWalletId() : "N/A", labelFont, valueFont);
            addRow(table, "Vi thu huong (Target):", tx.getTargetWalletId() != null ? tx.getTargetWalletId() : "N/A", labelFont, valueFont);
            addRow(table, "Phi giao dich (Fee):", CURRENCY_FMT.format(tx.getFee() != null ? tx.getFee() : 0) + " VND (Mien phi)", labelFont, valueFont);
            addRow(table, "Noi dung chuyen tien:", tx.getNote() != null ? tx.getNote() : "Chuyen tien", labelFont, valueFont);

            document.add(table);

            // Verification footer
            Paragraph stamp = new Paragraph("\n\nHE THONG NGAN HANG DIEN TU SEN HONG PAY DA XAC THUC TRUC TUYEN\nChung tu dien tu nay co gia tri phap ly theo Nghi dinh 52/2024/ND-CP ve thanh toan khong dung tien mat.", footerFont);
            stamp.setAlignment(Element.ALIGN_CENTER);
            document.add(stamp);

            document.close();
        } catch (DocumentException e) {
            log.error("Error generating receipt PDF: {}", e.getMessage(), e);
            throw new RuntimeException("Lỗi tạo biên lai PDF", e);
        }

        return out.toByteArray();
    }

    @Transactional(readOnly = true)
    public byte[] exportTransactions(String walletId, String format) {
        Page<Transaction> page = transactionRepository.findWalletHistory(walletId, "", PageRequest.of(0, 1000));
        List<Transaction> list = page.getContent();

        if ("pdf".equalsIgnoreCase(format)) {
            return exportTransactionsPdf(walletId, list);
        } else {
            return exportTransactionsCsv(list);
        }
    }

    private byte[] exportTransactionsCsv(List<Transaction> list) {
        StringBuilder sb = new StringBuilder();
        // UTF-8 BOM so Microsoft Excel renders Vietnamese correctly
        sb.append('\ufeff');
        sb.append("Mã giao dịch,Thời gian,Loại giao dịch,Số tiền (VND),Phí (VND),Trạng thái,Ví nguồn,Ví thụ hưởng,Nội dung\n");

        for (Transaction tx : list) {
            sb.append("\"").append(tx.getTransactionCode() != null ? tx.getTransactionCode() : tx.getId()).append("\",");
            sb.append("\"").append(tx.getCreatedAt() != null ? TIME_FMT.format(tx.getCreatedAt()) : "").append("\",");
            sb.append("\"").append(tx.getType()).append("\",");
            sb.append(tx.getAmount()).append(",");
            sb.append(tx.getFee() != null ? tx.getFee() : 0).append(",");
            sb.append("\"").append(tx.getStatus()).append("\",");
            sb.append("\"").append(tx.getSourceWalletId() != null ? tx.getSourceWalletId() : "").append("\",");
            sb.append("\"").append(tx.getTargetWalletId() != null ? tx.getTargetWalletId() : "").append("\",");
            sb.append("\"").append(tx.getNote() != null ? tx.getNote().replace("\"", "\"\"") : "").append("\"\n");
        }

        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    private byte[] exportTransactionsPdf(String walletId, List<Transaction> list) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4.rotate(), 20, 20, 30, 30);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            Font headerFont = new Font(Font.HELVETICA, 14, Font.BOLD, new Color(16, 185, 129));
            Font colFont = new Font(Font.HELVETICA, 9, Font.BOLD, Color.WHITE);
            Font rowFont = new Font(Font.HELVETICA, 8, Font.NORMAL, Color.BLACK);

            Paragraph p = new Paragraph("BANG SAO KE GIAO DICH - SEN HONG BANK\nVi tai khoan: " + walletId + "\n\n", headerFont);
            p.setAlignment(Element.ALIGN_CENTER);
            document.add(p);

            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{18f, 18f, 12f, 14f, 10f, 14f, 14f});

            String[] headers = {"Ma GD", "Thoi gian", "Loai GD", "So tien (VND)", "Trang thai", "Vi doi tac", "Noi dung"};
            for (String h : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(h, colFont));
                cell.setBackgroundColor(new Color(30, 41, 59));
                cell.setPadding(6);
                table.addCell(cell);
            }

            for (Transaction tx : list) {
                table.addCell(new Phrase(tx.getTransactionCode() != null ? tx.getTransactionCode() : tx.getId().substring(0, 8), rowFont));
                table.addCell(new Phrase(tx.getCreatedAt() != null ? TIME_FMT.format(tx.getCreatedAt()) : "", rowFont));
                table.addCell(new Phrase(tx.getType(), rowFont));
                table.addCell(new Phrase(CURRENCY_FMT.format(tx.getAmount()), rowFont));
                table.addCell(new Phrase(tx.getStatus(), rowFont));
                table.addCell(new Phrase(tx.getTargetWalletId() != null ? tx.getTargetWalletId() : "", rowFont));
                table.addCell(new Phrase(tx.getNote() != null ? tx.getNote() : "", rowFont));
            }

            document.add(table);
            document.close();
        } catch (DocumentException e) {
            log.error("Error creating statement PDF: {}", e.getMessage(), e);
            throw new RuntimeException("Lỗi xuất sao kê PDF", e);
        }

        return out.toByteArray();
    }

    private void addRow(PdfPTable table, String label, String value, Font labelFont, Font valueFont) {
        PdfPCell c1 = new PdfPCell(new Phrase(label, labelFont));
        c1.setBorder(Rectangle.BOTTOM);
        c1.setBorderColor(new Color(226, 232, 240));
        c1.setPadding(8);
        table.addCell(c1);

        PdfPCell c2 = new PdfPCell(new Phrase(value, valueFont));
        c2.setBorder(Rectangle.BOTTOM);
        c2.setBorderColor(new Color(226, 232, 240));
        c2.setPadding(8);
        table.addCell(c2);
    }
}
