import React from 'react';
import { CashDeposit } from '../types';
import { formatCurrency } from '../utils';
import { ShieldAlert, Check, X, Clock } from 'lucide-react';

interface ManagerQueueProps {
  deposits: CashDeposit[];
  currentUserId: string;
  onApprove: (id: string) => void;
  onReject: (id: string) => void;
}

export function ManagerQueue({ deposits, currentUserId, onApprove, onReject }: ManagerQueueProps) {
  return (
    <div className="card">
      <div className="card-header">
        <div className="card-title-text" style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
          <ShieldAlert size={18} color="var(--warning-amber)" />
          <span>HÀNG ĐỢI PHÊ DUYỆT CỦA KIỂM SOÁT VIÊN (MAKER-CHECKER)</span>
        </div>
        <span className="badge badge-amber">
          <Clock size={12} />
          <span>{deposits.length} Đang Chờ Duyệt</span>
        </span>
      </div>

      <div className="table-responsive">
        <table>
          <thead>
            <tr>
              <th>Mã Lệnh</th>
              <th>Khách Hàng</th>
              <th>Số Tiền Nạp</th>
              <th>Giao Dịch Viên</th>
              <th>Quyết Định</th>
            </tr>
          </thead>
          <tbody>
            {deposits.length === 0 ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '24px' }}>
                  Hiện tại không có lệnh nạp tiền nào vượt hạn mức cần phê duyệt
                </td>
              </tr>
            ) : deposits.map(d => (
              <tr key={d.id}>
                <td className="mono" style={{ fontWeight: 700, color: 'var(--primary-blue)' }}>{d.code}</td>
                <td>
                  <b style={{ color: 'var(--primary-navy)' }}>{d.customerName}</b>
                  <br />
                  <span className="mono" style={{ color: 'var(--text-muted)', fontSize: '11px' }}>
                    {d.citizenId ? `CCCD: ${d.citizenId}` : d.accountNumber}
                  </span>
                </td>
                <td className="mono" style={{ fontWeight: 800, color: 'var(--warning-amber)', fontSize: '14px' }}>
                  {formatCurrency(d.amount)}
                </td>
                <td>{d.makerName}</td>
                <td>
                  <div style={{ display: 'flex', gap: '6px' }}>
                    <button
                      type="button"
                      className="btn btn-success"
                      style={{ padding: '6px 14px', fontSize: '12px' }}
                      onClick={() => onApprove(d.id)}
                    >
                      <Check size={13} />
                      <span>Phê Duyệt</span>
                    </button>
                    <button
                      type="button"
                      className="btn btn-danger"
                      style={{ padding: '6px 14px', fontSize: '12px' }}
                      onClick={() => onReject(d.id)}
                    >
                      <X size={13} />
                      <span>Từ Chối</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}