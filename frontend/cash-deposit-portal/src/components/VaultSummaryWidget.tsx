import React from 'react';
import { VaultSummary } from '../types';
import { formatCurrency } from '../utils';
import { Briefcase, ShieldCheck, AlertTriangle, ArrowDownLeft, Scale, Building2, CheckCircle2, Clock, Download, FileSpreadsheet } from 'lucide-react';

interface VaultSummaryWidgetProps {
  summary: VaultSummary;
}

export function VaultSummaryWidget({ summary }: VaultSummaryWidgetProps) {
  const usagePct = ((summary.currentBalance / summary.maxLimit) * 100).toFixed(1);
  const pct = Math.min(100, parseFloat(usagePct));

  let badgeClass = 'badge badge-emerald';
  let badgeText = 'KÉT QUẦY AN TOÀN';
  let BadgeIcon = ShieldCheck;
  let barBg = '#10b981';

  if (pct > 90) {
    badgeClass = 'badge badge-rose';
    badgeText = 'VƯỢT HẠN MỨC';
    BadgeIcon = AlertTriangle;
    barBg = '#dc2626';
  } else if (pct > 70) {
    badgeClass = 'badge badge-amber';
    badgeText = 'TỒN CAO';
    BadgeIcon = AlertTriangle;
    barBg = '#f59e0b';
  }

  const handleExportVaultReport = () => {
    const now = new Date();
    const dateStr = now.toISOString().split('T')[0];
    const timeStr = now.toLocaleTimeString('vi-VN');

    const headers = '\ufeffBIÊN BẢN KIỂM KÊ KÉT QUỸ TIỀN MẶT CUỐI NGÀY (EOD) - SEN HỒNG BANK\n' +
      `Thời gian xuất:,${dateStr} ${timeStr}\n` +
      `Chi nhánh:,Chi nhánh Quận 1 (TP.HCM)\n` +
      `Trạng thái quỹ:,${badgeText}\n\n` +
      'Chỉ số kiểm kê,Số tiền (VND),Ghi chú\n' +
      `Tồn Quỹ Đầu Ngày,${summary.openingBalance},Số dư đầu ca\n` +
      `Tổng Thu Tiền Mặt Hôm Nay,${summary.totalCashIn},Tổng tiền nạp thành công\n` +
      `Tồn Quỹ Thực Tế Quầy,${summary.currentBalance},Tồn tiền mặt vật lý trong két\n` +
      `Hạn Mức An Toàn Két,${summary.maxLimit},Hạn mức quy định chi nhánh\n` +
      `Tỷ Lệ Sử Dụng Hạn Mức,${usagePct}%,${pct > 90 ? 'Vượt ngưỡng an toàn' : 'Trong hạn mức an toàn'}\n` +
      `Số Giao Dịch Nạp Thành Công,${summary.successCount},Giao dịch hoàn tất\n` +
      `Số Giao Dịch Chờ Kiểm Soát,${summary.pendingCount},Giao dịch chờ duyệt\n`;

    const blob = new Blob([headers], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bien-ban-kiem-ke-ket-quy-${dateStr}.csv`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  return (
    <div className="card">
      <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
        <div className="card-title-text" style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
          <Briefcase size={18} color="var(--primary-blue)" />
          <span>TỔNG KẾT KÉT QUỸ TIỀN MẶT TRONG NGÀY</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <button
            type="button"
            onClick={handleExportVaultReport}
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
              color: 'var(--primary-blue)',
              cursor: 'pointer',
            }}
          >
            <Download size={12} />
            <span>Xuất Biên Bản Kiểm Kê (CSV)</span>
          </button>
          <span className={badgeClass}>
            <BadgeIcon size={13} />
            <span>{badgeText}</span>
          </span>
        </div>
      </div>

      <div className="vault-grid">
        <div className="vault-metric">
          <span className="vault-metric-label">
            <Building2 size={13} />
            <span>Tồn Quỹ Đầu Ngày</span>
          </span>
          <span className="vault-metric-value mono" style={{ color: 'var(--text-secondary)' }}>
            {formatCurrency(summary.openingBalance)}
          </span>
        </div>
        <div className="vault-metric">
          <span className="vault-metric-label">
            <ArrowDownLeft size={13} color="var(--success-green)" />
            <span>Tổng Thu Hôm Nay</span>
          </span>
          <span className="vault-metric-value mono" style={{ color: 'var(--success-green)' }}>
            +{formatCurrency(summary.totalCashIn)}
          </span>
        </div>
        <div className="vault-metric">
          <span className="vault-metric-label">
            <Briefcase size={13} color="var(--primary-blue)" />
            <span>Tồn Quỹ Thực Tế Quầy</span>
          </span>
          <span className="vault-metric-value mono" style={{ color: 'var(--primary-blue)' }}>
            {formatCurrency(summary.currentBalance)}
          </span>
        </div>
        <div className="vault-metric">
          <span className="vault-metric-label">
            <ShieldCheck size={13} color="var(--warning-amber)" />
            <span>Hạn Mức An Toàn Quỹ</span>
          </span>
          <span className="vault-metric-value mono" style={{ color: 'var(--warning-amber)' }}>
            {formatCurrency(summary.maxLimit)}
          </span>
        </div>
      </div>

      <div style={{ marginTop: '12px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '6px' }}>
          <span style={{ color: 'var(--text-secondary)' }}>Tỷ lệ sử dụng hạn mức két quầy:</span>
          <span className="mono" style={{ fontWeight: 700, color: pct > 70 ? 'var(--warning-amber)' : 'var(--primary-blue)' }}>
            {usagePct}%
          </span>
        </div>
        <div className="progress-bar-container">
          <div className="progress-bar-fill" style={{ width: `${pct}%`, background: barBg }}></div>
        </div>
      </div>

      <div className="vault-footer-info">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', color: 'var(--success-green)', fontWeight: 700 }}>
            <CheckCircle2 size={13} />
            <span>{summary.successCount} Thành công</span>
          </span>
          <span style={{ color: 'var(--text-muted)' }}>|</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', color: 'var(--warning-amber)', fontWeight: 700 }}>
            <Clock size={13} />
            <span>{summary.pendingCount} Chờ duyệt</span>
          </span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--success-green)', fontWeight: 600 }}>
          <Scale size={13} />
          <span>Khớp 100% Sổ Cái TK 1011</span>
        </div>
      </div>
    </div>
  );
}