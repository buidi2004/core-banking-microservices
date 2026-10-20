import React from 'react';
import { LedgerBalance } from '../types';
import { formatCurrency } from '../utils';
import { Scale, CheckCircle2, AlertTriangle } from 'lucide-react';

interface DoubleEntryLedgerProps {
  ledger: LedgerBalance;
}

export function DoubleEntryLedger({ ledger }: DoubleEntryLedgerProps) {
  const isBalanced = ledger.delta === 0;

  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title-text" style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
          <Scale size={18} color="var(--primary-blue)" />
          <span>HẠCH TOÁN SỔ CÁI KÉP (DOUBLE-ENTRY BALANCE)</span>
        </div>
        <span className={isBalanced ? 'badge badge-emerald' : 'badge badge-rose'}>
          {isBalanced ? <CheckCircle2 size={12} /> : <AlertTriangle size={12} />}
          <span>Delta = {formatCurrency(ledger.delta)}</span>
        </span>
      </div>

      <div style={{ fontSize: '13px', lineHeight: '1.8' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--border-color)', padding: '8px 0' }}>
          <span style={{ color: 'var(--success-green)', fontWeight: 600 }}>● NỢ (Debit) TK 1011 - Quỹ tiền mặt quầy BR_Q1:</span>
          <span className="mono" style={{ fontWeight: 700, color: 'var(--success-green)' }}>
            +{formatCurrency(ledger.debit1011)}
          </span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid var(--border-color)', padding: '8px 0' }}>
          <span style={{ color: 'var(--primary-blue)', fontWeight: 600 }}>● CÓ (Credit) TK 4211 - Tiền gửi ví khách hàng:</span>
          <span className="mono" style={{ fontWeight: 700, color: 'var(--primary-blue)' }}>
            +{formatCurrency(ledger.credit4211)}
          </span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', fontWeight: 800, fontSize: '13.5px' }}>
          <span>Định lý bảo toàn tiền tệ (Δ Balance):</span>
          <span className="mono" style={{ color: isBalanced ? 'var(--success-green)' : 'var(--danger-red)' }}>
            {formatCurrency(ledger.delta)} {isBalanced ? '(CÂN BẰNG 100%)' : '(MẤT CÂN BẰNG!)'}
          </span>
        </div>
      </div>
    </div>
  );
}