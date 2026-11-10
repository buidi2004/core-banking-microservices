import React, { useState, useEffect } from 'react';
import { CashDeposit, LoggedInStaff, AmlTransaction } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { 
  History, Printer, CheckCircle2, Clock, XCircle, FileText, Download, 
  Search, ShieldAlert, ShieldCheck, Filter, RefreshCw 
} from 'lucide-react';

interface TransactionHistoryProps {
  deposits: CashDeposit[];
  onReceipt: (deposit: CashDeposit) => void;
  staff?: LoggedInStaff | null;
}

export function TransactionHistory({ deposits, onReceipt, staff }: TransactionHistoryProps) {
  const [activeView, setActiveView] = useState<'STANDARD' | 'AML'>('STANDARD');
  const [searchTerm, setSearchTerm] = useState('');
  const [exporting, setExporting] = useState(false);

  // AML specific state
  const [amlTransactions, setAmlTransactions] = useState<AmlTransaction[]>([]);
  const [amlLoading, setAmlLoading] = useState(false);
  const [amlThreshold, setAmlThreshold] = useState<number>(400000000); // 400 Triệu theo Luật PCRT 2022
  const [amlStandardText, setAmlStandardText] = useState<string>('Luật Phòng, chống rửa tiền 2022 (Ngưỡng báo cáo >= 400.000.000 VND)');

  // Load AML data when AML tab is active or threshold changes
  const loadAmlTransactions = async (threshold: number) => {
    setAmlLoading(true);
    try {
      const res = await ApiService.fetchAmlLargeTransactions(staff, threshold, 0, 100);
      if (res && res.content) {
        setAmlTransactions(res.content);
        if (res.standard) setAmlStandardText(res.standard);
      } else {
        setAmlTransactions([]);
      }
    } catch (e) {
      console.error('Failed to load AML transactions:', e);
      setAmlTransactions([]);
    } finally {
      setAmlLoading(false);
    }
  };

  useEffect(() => {
    if (activeView === 'AML') {
      loadAmlTransactions(amlThreshold);
    }
  }, [activeView, amlThreshold]);

  const handleExportCsv = async () => {
    setExporting(true);
    try {
      if (activeView === 'AML') {
        const now = new Date().toISOString().split('T')[0];
        const headers = '\ufeffMã Giao Dịch,Mã GD Tham Chiếu,Loại GD,Số Tiền (VND),Phí GD,Ví Nguồn,Ví Đích,Trạng Thái,Thời Gian,Tiêu Chuẩn Pháp Lý\n';
        const rows = amlTransactions.map(tx =>
          `"${tx.id}","${tx.transactionCode || tx.id}","${tx.type}",${tx.amount},${tx.fee || 0},"${tx.sourceWalletId || ''}","${tx.targetWalletId || ''}","${tx.status}","${tx.createdAt || tx.timestamp || ''}","Luật PCRT 2022 (Ngưỡng >= ${formatCurrency(amlThreshold)})"`
        ).join('\n');

        const csvBlob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
        const url = window.URL.createObjectURL(csvBlob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `bao-cao-aml-gia-tri-lon-${now}.csv`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } else {
        const blob = await ApiService.exportTransactionsCsv(staff);
        if (blob && blob.size > 0) {
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `transactions-statement-${new Date().toISOString().split('T')[0]}.csv`;
          document.body.appendChild(a);
          a.click();
          window.URL.revokeObjectURL(url);
          document.body.removeChild(a);
        } else {
          // Fallback: tạo CSV từ dữ liệu deposits hiện tại
          const headers = '\ufeffMã GD,Họ Tên Khách Hàng,Số Tài Khoản,Số Tiền,Trạng Thái,Thời Gian\n';
          const rows = deposits.map(d => `"${d.code}","${d.customerName}","${d.accountNumber}",${d.amount},"${d.status}","${d.timestamp}"`).join('\n');
          const csvBlob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
          const url = window.URL.createObjectURL(csvBlob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `transactions-local-${new Date().toISOString().split('T')[0]}.csv`;
          document.body.appendChild(a);
          a.click();
          window.URL.revokeObjectURL(url);
          document.body.removeChild(a);
        }
      }
    } catch (e: any) {
      alert('Lỗi xuất sao kê CSV: ' + e.message);
    } finally {
      setExporting(false);
    }
  };

  const filteredDeposits = deposits.filter(d => {
    if (!searchTerm.trim()) return true;
    const term = searchTerm.toLowerCase();
    return d.code.toLowerCase().includes(term) ||
      d.customerName.toLowerCase().includes(term) ||
      d.accountNumber.toLowerCase().includes(term);
  });

  const filteredAmlTransactions = amlTransactions.filter(tx => {
    if (!searchTerm.trim()) return true;
    const term = searchTerm.toLowerCase();
    return (
      tx.id.toLowerCase().includes(term) ||
      (tx.transactionCode && tx.transactionCode.toLowerCase().includes(term)) ||
      (tx.sourceWalletId && tx.sourceWalletId.toLowerCase().includes(term)) ||
      (tx.targetWalletId && tx.targetWalletId.toLowerCase().includes(term))
    );
  });

  const totalAmlAmount = amlTransactions.reduce((acc, tx) => acc + (tx.amount || 0), 0);

  return (
    <div className="card">
      {/* Header with Switcher Tabs */}
      <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <button
            type="button"
            onClick={() => setActiveView('STANDARD')}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: activeView === 'STANDARD' ? '1px solid var(--primary-blue)' : '1px solid var(--border-color)',
              background: activeView === 'STANDARD' ? 'var(--primary-blue)' : 'var(--bg-subtle)',
              color: activeView === 'STANDARD' ? '#ffffff' : 'var(--text-main)',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '5px'
            }}
          >
            <History size={14} />
            <span>Giao Dịch Quầy</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveView('AML')}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: activeView === 'AML' ? '1px solid #dc2626' : '1px solid var(--border-color)',
              background: activeView === 'AML' ? '#dc2626' : 'var(--bg-subtle)',
              color: activeView === 'AML' ? '#ffffff' : '#dc2626',
              fontSize: '12px',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '5px'
            }}
          >
            <ShieldAlert size={14} />
            <span>Giám Sát AML &ge; 400M</span>
          </button>
        </div>

        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button
            type="button"
            onClick={handleExportCsv}
            disabled={exporting}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              padding: '4px 10px',
              borderRadius: '6px',
              border: '1px solid var(--border-color)',
              background: 'var(--bg-subtle)',
              fontSize: '11px',
              fontWeight: 600,
              color: activeView === 'AML' ? '#dc2626' : 'var(--primary-blue)',
              cursor: 'pointer',
            }}
          >
            <Download size={12} />
            <span>{activeView === 'AML' ? 'Xuất Báo Cáo AML' : 'Xuất CSV'}</span>
          </button>
          <span className="badge badge-emerald">
            <CheckCircle2 size={12} />
            <span>Realtime Outbox</span>
          </span>
        </div>
      </div>

      {/* AML Notification Banner */}
      {activeView === 'AML' && (
        <div style={{
          margin: '10px 16px 0 16px',
          padding: '10px 14px',
          borderRadius: '8px',
          background: 'rgba(239, 68, 68, 0.08)',
          border: '1px solid rgba(239, 68, 68, 0.25)',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ShieldAlert size={16} color="#dc2626" />
              <span style={{ fontSize: '12.5px', fontWeight: 700, color: '#dc2626' }}>
                Tuân thủ Luật Phòng, chống rửa tiền 2022
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Ngưỡng báo cáo:</span>
              <select
                value={amlThreshold}
                onChange={e => setAmlThreshold(Number(e.target.value))}
                style={{
                  padding: '3px 8px',
                  borderRadius: '4px',
                  border: '1px solid var(--border-color)',
                  background: 'var(--bg-input)',
                  fontSize: '11.5px',
                  fontWeight: 600,
                  color: 'var(--text-main)',
                  cursor: 'pointer'
                }}
              >
                <option value={400000000}>&ge; 400 Triệu (Chuẩn Luật PCRT 2022)</option>
                <option value={500000000}>&ge; 500 Triệu</option>
                <option value={1000000000}>&ge; 1 Tỷ Đồng</option>
                <option value={50000000}>&ge; 50 Triệu (Kiểm tra mở rộng)</option>
              </select>
              <button
                type="button"
                onClick={() => loadAmlTransactions(amlThreshold)}
                style={{
                  padding: '3px 8px',
                  background: 'none',
                  border: '1px solid var(--border-color)',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  color: 'var(--text-muted)'
                }}
                title="Làm mới dữ liệu AML"
              >
                <RefreshCw size={12} className={amlLoading ? 'spin' : ''} />
              </button>
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '11.5px', color: 'var(--text-muted)' }}>
            <span>Phát hiện: <strong style={{ color: '#dc2626' }}>{amlTransactions.length}</strong> giao dịch giá trị lớn</span>
            <span>Tổng giá trị kiểm soát: <strong style={{ color: 'var(--text-main)' }}>{formatCurrency(totalAmlAmount)}</strong></span>
          </div>
        </div>
      )}

      {/* Search Bar */}
      <div style={{ padding: '8px 16px 4px 16px' }}>
        <div style={{ position: 'relative' }}>
          <Search size={14} style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input
            type="text"
            placeholder={activeView === 'AML' ? 'Lọc theo Mã GD hoặc Wallet ID...' : 'Lọc theo Mã GD hoặc Số tài khoản...'}
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '6px 10px 6px 30px',
              borderRadius: '6px',
              border: '1px solid var(--border-color)',
              background: 'var(--bg-input)',
              color: 'var(--text-main)',
              fontSize: '12px',
            }}
          />
        </div>
      </div>

      {/* Main Table */}
      <div className="table-responsive">
        {activeView === 'STANDARD' ? (
          <table>
            <thead>
              <tr>
                <th>Mã GD</th>
                <th>Khách Hàng</th>
                <th>Số Tiền</th>
                <th>Thời Gian</th>
                <th>Trạng Thái</th>
                <th>Chứng Từ</th>
              </tr>
            </thead>
            <tbody>
              {filteredDeposits.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '24px', color: 'var(--text-muted)', fontSize: '13px' }}>
                    Không tìm thấy giao dịch nạp quầy nào phù hợp
                  </td>
                </tr>
              ) : (
                filteredDeposits.map(d => (
                  <tr key={d.id}>
                    <td className="mono" style={{ fontWeight: 700, color: 'var(--primary-blue)', fontSize: '12px' }}>{d.code}</td>
                    <td>
                      <b style={{ color: 'var(--primary-navy)', fontSize: '12.5px' }}>{d.customerName}</b>
                      <div className="mono" style={{ color: 'var(--text-muted)', fontSize: '11px' }}>
                        {d.phoneNumber || d.accountNumber}
                      </div>
                    </td>
                    <td className="mono" style={{ fontWeight: 800, fontSize: '13px', color: 'var(--success-green)' }}>
                      +{formatCurrency(d.amount)}
                    </td>
                    <td style={{ fontSize: '11.5px', color: 'var(--text-muted)' }}>
                      {d.timestamp ? new Date(d.timestamp).toLocaleString('vi-VN') : '—'}
                    </td>
                    <td>
                      <span className={`badge ${d.status === 'COMPLETED' ? 'badge-emerald' : d.status === 'PENDING_APPROVAL' ? 'badge-amber' : 'badge-rose'}`}>
                        {d.status === 'COMPLETED' && <CheckCircle2 size={11} />}
                        {d.status === 'PENDING_APPROVAL' && <Clock size={11} />}
                        {d.status === 'REJECTED' && <XCircle size={11} />}
                        <span>{d.status === 'COMPLETED' ? 'Thành công' : d.status === 'PENDING_APPROVAL' ? 'Chờ duyệt' : 'Bị từ chối'}</span>
                      </span>
                    </td>
                    <td>
                      {d.status === 'COMPLETED' ? (
                        <button
                          type="button"
                          onClick={() => onReceipt(d)}
                          className="btn btn-outline"
                          style={{ padding: '4px 12px', fontSize: '11.5px', gap: '4px' }}
                        >
                          <Printer size={12} />
                          <span>In Phiếu</span>
                        </button>
                      ) : d.status === 'PENDING_APPROVAL' ? (
                        <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>Đang chờ duyệt</span>
                      ) : (
                        <span style={{ color: 'var(--danger-red)', fontSize: '12px' }}>Từ chối</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Mã Giao Dịch</th>
                <th>Loại GD</th>
                <th>Số Tiền</th>
                <th>Ví Nguồn &rarr; Ví Đích</th>
                <th>Pháp Lý AML</th>
              </tr>
            </thead>
            <tbody>
              {amlLoading ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)', fontSize: '12.5px' }}>
                    Đang tải báo cáo AML từ Cục Phòng Chống Rửa Tiền...
                  </td>
                </tr>
              ) : filteredAmlTransactions.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '20px', color: 'var(--text-muted)', fontSize: '12.5px' }}>
                    Không có giao dịch nào &ge; {formatCurrency(amlThreshold)} trong hệ thống
                  </td>
                </tr>
              ) : (
                filteredAmlTransactions.map(tx => (
                  <tr key={tx.id}>
                    <td className="mono" style={{ fontWeight: 700, color: '#dc2626', fontSize: '11.5px' }}>
                      {tx.transactionCode || tx.id}
                      <div style={{ fontSize: '10px', color: 'var(--text-muted)' }}>
                        {tx.createdAt ? new Date(tx.createdAt).toLocaleString('vi-VN') : ''}
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-subtle" style={{ fontSize: '10px' }}>
                        {tx.type}
                      </span>
                    </td>
                    <td className="mono" style={{ fontWeight: 800, color: '#dc2626' }}>
                      {formatCurrency(tx.amount)}
                    </td>
                    <td style={{ fontSize: '11px' }}>
                      <div className="mono" style={{ color: 'var(--text-muted)' }}>
                        Từ: {tx.sourceWalletId ? `${tx.sourceWalletId.substring(0, 10)}...` : 'Két quỹ chi nhánh'}
                      </div>
                      <div className="mono" style={{ color: 'var(--primary-blue)', fontWeight: 600 }}>
                        Đến: {tx.targetWalletId ? `${tx.targetWalletId.substring(0, 10)}...` : 'Ví thụ hưởng'}
                      </div>
                    </td>
                    <td>
                      <span className="badge badge-rose" style={{ display: 'inline-flex', alignItems: 'center', gap: '3px', fontSize: '10px' }}>
                        <ShieldAlert size={10} />
                        <span>Báo cáo NHNN</span>
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
