import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionType;

import java.time.Instant;
import java.util.List;

public interface TransactionQueryUseCase {
    List<Transaction> getTransactionHistory(String walletId, TransactionType type, int page, int size);
    Transaction getTransactionById(String transactionId);
    byte[] exportStatementCsv(String walletId, Instant fromDate, Instant toDate);
    byte[] exportStatementPdf(String walletId, Instant fromDate, Instant toDate);
    byte[] exportStatementExcel(String walletId, Instant fromDate, Instant toDate);
}

