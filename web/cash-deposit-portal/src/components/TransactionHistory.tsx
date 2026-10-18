import React from 'react';
import { CashDeposit } from '../types';
import { formatCurrency } from '../utils';
import { History, Printer, CheckCircle2, Clock, XCircle, FileText } from 'lucide-react';

interface TransactionHistoryProps {
  deposits: CashDeposit[];
  onReceipt: (deposit: CashDeposit) => void;
}

export function TransactionHistory({ deposits, onReceipt }: TransactionHistoryProps) {
  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title-text" style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
          <History size={18} color="var(--primary-blue)" />
          <span>LỊCH SỬ GIAO DỊCH GẦN NHẤT</span>
        </div>
        <span className="badge badge-emerald">
          <CheckCircle2 size={12} />
          <span>Realtime Outbox</span>
        </span>
      </div>

      <div className="table-responsive">
        <table>
          <thead>
            <tr>
              <th>Mã GD</th>
              <th>Số Tiền</th>
              <th>Trạng Thái</th>
              <th>Chứng Từ</th>
            </tr>
          </thead>
          <tbody>
            {deposits.map(d => (
              <tr key={d.id}>
                <td className="mono" style={{ fontWeight: 700, color: 'var(--primary-blue)' }}>{d.code}</td>
                <td className="mono" style={{ fontWeight: 800 }}>{formatCurrency(d.amount)}</td>
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
                    <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>Đang chờ</span>
                  ) : (
                    <span style={{ color: 'var(--danger-red)', fontSize: '12px' }}>Từ chối</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}