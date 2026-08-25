package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.WalletNotFoundException;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.GenerateReceiptUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.lowagie.text.Document;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Service
public class ReceiptService implements GenerateReceiptUseCase {

    private final TransactionPersistencePort transactionPersistencePort;
    private final GetWalletUseCase getWalletUseCase;

    public ReceiptService(TransactionPersistencePort transactionPersistencePort,
                          GetWalletUseCase getWalletUseCase) {
        this.transactionPersistencePort = transactionPersistencePort;
        this.getWalletUseCase = getWalletUseCase;
    }

    @Override
    public byte[] generateReceiptPdf(String transactionId, String userId) {
        Transaction tx = transactionPersistencePort.findTransactionById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        // Verify IDOR: user must be the owner of either source or target wallet
        boolean authorized = false;
        Wallet sourceWallet = null;
        Wallet targetWallet = null;

        if (tx.getSourceWalletId() != null) {
            try {
                sourceWallet = getWalletUseCase.getWalletById(tx.getSourceWalletId());
                if (sourceWallet.getOwnerId().equals(userId)) {
                    authorized = true;
                }
            } catch (WalletNotFoundException ignored) {}
        }

        if (tx.getTargetWalletId() != null) {
            try {
                targetWallet = getWalletUseCase.getWalletById(tx.getTargetWalletId());
                if (targetWallet.getOwnerId().equals(userId)) {
                    authorized = true;
                }
            } catch (WalletNotFoundException ignored) {}
        }

        if (!authorized) {
            throw new IllegalArgumentException("Unauthorized to view this receipt");
        }

        return createPdf(tx, sourceWallet, targetWallet);
    }

    private byte[] createPdf(Transaction tx, Wallet sourceWallet, Wallet targetWallet) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document document = new Document();
            PdfWriter.getInstance(document, out);
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Paragraph title = new Paragraph("E-WALLET RECEIPT", titleFont);
            title.setAlignment(com.lowagie.text.Element.ALIGN_CENTER);
            document.add(title);

            document.add(new Paragraph(" "));

            PdfPTable table = new PdfPTable(2);
            table.setWidthPercentage(100);
            
            addTableRow(table, "Transaction ID", tx.getId());
            
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
                    .withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
            addTableRow(table, "Date & Time", formatter.format(tx.getCreatedAt()) + " (GMT+7)");
            
            addTableRow(table, "Type", tx.getType().name());
            addTableRow(table, "Amount", tx.getAmount().getAmount().toPlainString() + " " + tx.getAmount().getCurrency());
            addTableRow(table, "Status", tx.getStatus().name());

            if (tx.getSourceWalletId() != null) {
                String sourceName = getWalletUseCase.getRecipientInfo(tx.getSourceWalletId(), null).getMaskedName();
                addTableRow(table, "Sender", sourceName + " (Wallet: " + tx.getSourceWalletId() + ")");
            }

            if (tx.getTargetWalletId() != null) {
                String targetName = getWalletUseCase.getRecipientInfo(tx.getTargetWalletId(), null).getMaskedName();
                addTableRow(table, "Recipient", targetName + " (Wallet: " + tx.getTargetWalletId() + ")");
            }
            
            if (tx.getOriginalTransactionId() != null) {
                addTableRow(table, "Ref. Tx ID", tx.getOriginalTransactionId());
            }

            document.add(table);
            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF receipt", e);
        }
    }

    private void addTableRow(PdfPTable table, String key, String value) {
        Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);
        PdfPCell keyCell = new PdfPCell(new Paragraph(key, boldFont));
        keyCell.setBorder(com.lowagie.text.Rectangle.NO_BORDER);
        keyCell.setPadding(5);
        
        PdfPCell valueCell = new PdfPCell(new Paragraph(value));
        valueCell.setBorder(com.lowagie.text.Rectangle.NO_BORDER);
        valueCell.setPadding(5);
        
        table.addCell(keyCell);
        table.addCell(valueCell);
    }
}
