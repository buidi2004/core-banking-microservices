import React, { useState, useEffect, useCallback } from 'react';
import { LedgerReconciliation, LedgerJournalEntry, LoggedInStaff } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { 
  Scale, CheckCircle2, AlertTriangle, RefreshCw, FileSpreadsheet, 
  Search, ArrowDownRight, ArrowUpRight, ShieldCheck, Database
} from 'lucide-react';

interface LedgerManagementProps {
  staff: LoggedInStaff;
}

export function LedgerManagement({ staff }: LedgerManagementProps) {
  const [reconciliation, setReconciliation] = useState<LedgerReconciliation | null>(null);
  const [entries, setEntries] = useState<LedgerJournalEntry[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedEntry, setSelectedEntry] = useState<LedgerJournalEntry | null>(null);

  const fetchLedgerData = useCallback(async () => {
    setLoading(true);
    try {
      const [recon, journalEntries] = await Promise.all([
        ApiService.fetchLedgerBalanceCheck(staff),
        ApiService.fetchJournalEntries(staff),
      ]);
      if (recon) setReconciliation(recon);
      if (journalEntries) setEntries(journalEntries);
    } catch (e) {
      console.error('Error fetching ledger data:', e);
    } finally {
      setLoading(false);
    }
  }, [staff]);

  useEffect(() => {
    fetchLedgerData();
  }, [fetchLedgerData]);

  const isBalanced = reconciliation ? reconciliation.delta === 0 && reconciliation.balanced : true;

  const filteredEntries = entries.filter(e => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return (
      e.id.toLowerCase().includes(term) ||
      e.transactionId.toLowerCase().includes(term) ||
      (e.description && e.description.toLowerCase().includes(term))
    );
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        background: 'var(--bg-card)',
        padding: '18px 24px',
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--border-color)',
        boxShadow: 'var(--shadow-card)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{
            background: isBalanced ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
            padding: '12px',
            borderRadius: '12px',
            color: isBalanced ? 'var(--success-green)' : 'var(--danger-red)'
          }}>
            <Scale size={28} />
          </div>
          <div>
            <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)' }}>
              SỔ CÁI KÉP TOÀN DIỆN &amp; ĐỐI SOÁT BÚT TOÁN (DOUBLE-ENTRY RECONCILIATION)
            </h2>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-muted)' }}>
              Bảo toàn bất biến kế toán: Tổng phát sinh Nợ = Tổng phát sinh Có (Δ = 0.00 VND) trên toàn hệ thống 6 microservices
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={fetchLedgerData}
          disabled={loading}
          className="btn btn-outline"
          style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 16px' }}
        >
          <RefreshCw size={14} className={loading ? 'spin' : ''} />
          <span>Đối soát tức thời</span>
        </button>
      </div>

      {/* Đối soát Bất biến Kế toán (Reconciliation Banner) */}
      <div style={{
        background: isBalanced ? 'linear-gradient(135deg, #064e3b 0%, #047857 100%)' : '#7f1d1d',
        color: '#ffffff',
        padding: '24px',
        borderRadius: 'var(--radius-card)',
        boxShadow: '0 4px 14px rgba(0,0,0,0.1)'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <ShieldCheck size={22} />
            <span style={{ fontSize: '16px', fontWeight: 800, letterSpacing: '0.5px' }}>
              CHỨNG NHẬN ĐỐI SOÁT SỔ CÁI (AUTOMATIC RECONCILIATION)
            </span>
          </div>
          <span style={{
            background: isBalanced ? 'rgba(255,255,255,0.2)' : 'rgba(255,0,0,0.3)',
            padding: '4px 14px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: 700
          }}>
            {isBalanced ? '✓ TRẠNG THÁI: CÂN BẰNG HOÀN TOÀN (100%)' : '⚠ CẢNH BÁO: MẤT CÂN BẰNG SỔ CÁI'}
          </span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', paddingTop: '10px' }}>
          <div style={{ background: 'rgba(0,0,0,0.15)', padding: '16px', borderRadius: '10px' }}>
            <div style={{ fontSize: '12px', opacity: 0.9 }}>TỔNG PHÁT SINH NỢ (Σ DEBIT)</div>
            <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px' }}>
              {formatCurrency(reconciliation?.totalDebit || 0)}
            </div>
            <div style={{ fontSize: '11px', opacity: 0.8, marginTop: '4px' }}>Bao gồm TK 1011 (Tiền mặt), TK 1113, TK 4211</div>
          </div>

          <div style={{ background: 'rgba(0,0,0,0.15)', padding: '16px', borderRadius: '10px' }}>
            <div style={{ fontSize: '12px', opacity: 0.9 }}>TỔNG PHÁT SINH CÓ (Σ CREDIT)</div>
            <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px' }}>
              {formatCurrency(reconciliation?.totalCredit || 0)}
            </div>
            <div style={{ fontSize: '11px', opacity: 0.8, marginTop: '4px' }}>Bao gồm TK 4211 (Ví khách hàng), TK 3941</div>
          </div>

          <div style={{ background: 'rgba(0,0,0,0.15)', padding: '16px', borderRadius: '10px' }}>
            <div style={{ fontSize: '12px', opacity: 0.9 }}>ĐỘ LỆCH SỔ CÁI (DELTA = |ΣD - ΣC|)</div>
            <div className="mono" style={{ fontSize: '24px', fontWeight: 800, marginTop: '8px', color: isBalanced ? '#a7f3d0' : '#fca5a5' }}>
              {formatCurrency(reconciliation?.delta || 0)}
            </div>
            <div style={{ fontSize: '11px', opacity: 0.8, marginTop: '4px' }}>
              {isBalanced ? 'Đạt chuẩn Kiểm toán Quốc tế (0.00 VND)' : 'Cần kiểm tra giao dịch dở dang!'}
            </div>
          </div>
        </div>
      </div>

      {/* Tra cứu Chứng Từ Ghi Sổ (Journal Entries Table) */}
      <div className="card" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
            <FileSpreadsheet size={18} color="var(--primary-blue)" />
            <span>NHẬT KÝ CHỨNG TỪ GHI SỔ GỐC (JOURNAL ENTRIES - {entries.length} CHỨNG TỪ)</span>
          </div>

          <div style={{ position: 'relative', width: '320px' }}>
            <input
              type="text"
              placeholder="Tìm theo mã giao dịch, mã chứng từ..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px 8px 32px',
                borderRadius: '6px',
                border: '1px solid var(--border-color)',
                fontSize: '12.5px',
                background: 'var(--bg-main)'
              }}
            />
            <Search size={14} style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--text-muted)' }} />
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', borderCollapse: 'collapse', fontSize: '12.5px' }}>
            <thead>
              <tr style={{ background: 'var(--bg-card-subtle)', textAlign: 'left', borderBottom: '1px solid var(--border-color)' }}>
                <th style={{ padding: '10px 14px', fontWeight: 700 }}>MÃ CHỨNG TỪ</th>
                <th style={{ padding: '10px 14px', fontWeight: 700 }}>MÃ GIAO DỊCH GỐC</th>
                <th style={{ padding: '10px 14px', fontWeight: 700 }}>LOẠI NGHIỆP VỤ</th>
                <th style={{ padding: '10px 14px', fontWeight: 700 }}>DIỄN GIẢI KẾ TOÁN</th>
                <th style={{ padding: '10px 14px', fontWeight: 700, textAlign: 'center' }}>BÚT TOÁN</th>
                <th style={{ padding: '10px 14px', fontWeight: 700, textAlign: 'center' }}>TRẠNG THÁI</th>
                <th style={{ padding: '10px 14px', fontWeight: 700, textAlign: 'right' }}>THỜI GIAN</th>
              </tr>
            </thead>
            <tbody>
              {filteredEntries.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '30px', color: 'var(--text-muted)' }}>
                    Không có chứng từ ghi sổ nào.
                  </td>
                </tr>
              ) : (
                filteredEntries.map(entry => (
                  <React.Fragment key={entry.id}>
                    <tr
                      onClick={() => setSelectedEntry(selectedEntry?.id === entry.id ? null : entry)}
                      style={{
                        cursor: 'pointer',
                        borderBottom: '1px solid var(--border-color)',
                        background: selectedEntry?.id === entry.id ? 'var(--bg-card-subtle)' : 'transparent'
                      }}
                    >
                      <td style={{ padding: '10px 14px' }}>
                        <span className="mono" style={{ fontWeight: 700, color: 'var(--primary-blue)' }}>
                          {entry.id.substring(0, 8)}...
                        </span>
                      </td>
                      <td style={{ padding: '10px 14px' }}>
                        <span className="mono" style={{ fontWeight: 600 }}>{entry.transactionId}</span>
                      </td>
                      <td style={{ padding: '10px 14px' }}>
                        <span className="badge badge-cyan" style={{ fontSize: '10.5px' }}>
                          {entry.transactionType || 'POSTED_ENTRY'}
                        </span>
                      </td>
                      <td style={{ padding: '10px 14px', color: 'var(--text-main)', maxWidth: '300px' }}>
                        {entry.description}
                      </td>
                      <td style={{ padding: '10px 14px', textAlign: 'center' }}>
                        <span className="badge badge-emerald" style={{ fontSize: '11px' }}>
                          {(entry.postings?.length || 2)} bút toán
                        </span>
                      </td>
                      <td style={{ padding: '10px 14px', textAlign: 'center' }}>
                        <span className="badge badge-emerald" style={{ fontSize: '10.5px' }}>
                          {entry.status}
                        </span>
                      </td>
                      <td style={{ padding: '10px 14px', textAlign: 'right', color: 'var(--text-muted)', fontSize: '11px' }}>
                        {new Date(entry.createdAt).toLocaleString('vi-VN')}
                      </td>
                    </tr>

                    {/* Chi Tiết Các Bút Toán Con (Postings) Khi Click */}
                    {selectedEntry?.id === entry.id && entry.postings && entry.postings.length > 0 && (
                      <tr style={{ background: 'var(--bg-card-subtle)' }}>
                        <td colSpan={7} style={{ padding: '12px 24px' }}>
                          <div style={{
                            background: 'var(--bg-card)',
                            padding: '12px 16px',
                            borderRadius: '8px',
                            border: '1px solid var(--border-color)'
                          }}>
                            <div style={{ fontSize: '12px', fontWeight: 700, marginBottom: '8px', color: 'var(--primary-navy)' }}>
                              CHI TIẾT ĐỊNH KHOẢN HẠCH TOÁN (POSTINGS):
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                              {entry.postings.map((p, idx) => {
                                const isDebit = (p.type || '').toUpperCase() === 'DEBIT';
                                return (
                                  <div
                                    key={p.id || idx}
                                    style={{
                                      display: 'flex',
                                      justifyContent: 'space-between',
                                      alignItems: 'center',
                                      padding: '6px 12px',
                                      borderRadius: '6px',
                                      background: isDebit ? 'rgba(16, 185, 129, 0.06)' : 'rgba(59, 130, 246, 0.06)',
                                      fontSize: '12px'
                                    }}
                                  >
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                      {isDebit ? (
                                        <ArrowDownRight size={14} color="var(--success-green)" />
                                      ) : (
                                        <ArrowUpRight size={14} color="var(--primary-blue)" />
                                      )}
                                      <span style={{ fontWeight: 700, color: isDebit ? 'var(--success-green)' : 'var(--primary-blue)' }}>
                                        {isDebit ? 'NỢ (Debit)' : 'CÓ (Credit)'}
                                      </span>
                                      <span className="mono" style={{ color: 'var(--text-muted)' }}>
                                        TK: {p.accountNumber || p.accountId}
                                      </span>
                                    </div>
                                    <span className="mono" style={{ fontWeight: 800, color: isDebit ? 'var(--success-green)' : 'var(--primary-blue)' }}>
                                      {isDebit ? '+' : '-'}{formatCurrency(p.amount)} {p.currency}
                                    </span>
                                  </div>
                                );
                              })}
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

