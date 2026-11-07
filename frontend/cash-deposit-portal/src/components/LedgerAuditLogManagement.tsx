import React, { useState, useEffect } from 'react';
import { LoggedInStaff, LedgerAuditLog, AuditLogFilter } from '../types';
import { ApiService } from '../api';
import { formatDateVi } from '../utils';
import { ScrollText, RefreshCw, Search, Filter } from 'lucide-react';

interface LedgerAuditLogManagementProps {
  currentStaff: LoggedInStaff;
}

export function LedgerAuditLogManagement({ currentStaff }: LedgerAuditLogManagementProps) {
  const [logs, setLogs] = useState<LedgerAuditLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState<AuditLogFilter>({ actorId: '', entityType: '', entityId: '', correlationId: '' });

  const isManager = currentStaff.role === 'MANAGER';

  const loadData = async () => {
    if (!isManager) return;
    setLoading(true);
    try {
      const data = await ApiService.fetchLedgerAuditLogs(currentStaff, filters);
      setLogs(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, []);

  const filteredLogs = logs.filter(item => {
    const q = searchTerm.toLowerCase();
    if (q === '') return true;
    return item.eventType.toLowerCase().includes(q)
      || item.entityType.toLowerCase().includes(q)
      || item.entityId.toLowerCase().includes(q)
      || (item.performedBy || '').toLowerCase().includes(q)
      || (item.correlationId || '').toLowerCase().includes(q)
      || (item.description || '').toLowerCase().includes(q);
  });

  const handleReset = () => {
    setFilters({ actorId: '', entityType: '', entityId: '', correlationId: '' });
  };

  if (!isManager) {
    return (
      <div className="card" style={{ padding: '32px', textAlign: 'center' }}>
        <ScrollText size={44} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
        <h2 style={{ fontSize: '16px', fontWeight: 800, color: 'var(--primary-navy)' }}>Chức năng dành cho Kiểm soát viên</h2>
        <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '6px' }}>
          Nhật ký kiểm toán sổ cái chỉ dành cho vai trò Quản lý (ROLE_MANAGER) theo quy định kiểm soát nội bộ.
        </p>
      </div>
    );
  }

  return (
    <div className="card" style={{ padding: '24px' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ScrollText size={20} color="var(--primary-blue)" />
            NHẬT KÝ KIỂM TOÁN SỔ CÁI (LEDGER AUDIT TRAIL)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Truy vết mọi thao tác ghi sổ, điều chỉnh bút toán và hành động của cán bộ — tối đa 500 bản ghi gần nhất
          </p>
        </div>
        <button type="button" className="btn btn-outline" onClick={loadData} disabled={loading} style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}>
          <RefreshCw size={14} className={loading ? 'spin' : ''} />
          Làm mới
        </button>
      </div>

      {/* Bộ lọc truy vết */}
      <div style={{ background: 'var(--bg-light)', border: '1px solid var(--border-color)', borderRadius: '10px', padding: '16px', marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '10px', fontSize: '12px', fontWeight: 800, color: 'var(--text-muted)' }}>
          <Filter size={13} /> TRUY VẾT CHUYÊN SÂU (ưu tiên: Correlation ID → Actor → Entity)
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1.2fr 1fr 1fr auto auto', gap: '10px', alignItems: 'end' }}>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>CORRELATION ID</label>
            <input className="input" style={{ width: '100%', fontSize: '13px' }} value={filters.correlationId} onChange={e => setFilters(f => ({ ...f, correlationId: e.target.value }))} placeholder="Trace ID liên kết chuỗi thao tác" />
          </div>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>ACTOR ID (CÁN BỘ THỰC HIỆN)</label>
            <input className="input" style={{ width: '100%', fontSize: '13px' }} value={filters.actorId} onChange={e => setFilters(f => ({ ...f, actorId: e.target.value }))} placeholder="userId / staffId" />
          </div>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>ENTITY TYPE</label>
            <input className="input" style={{ width: '100%', fontSize: '13px' }} value={filters.entityType} onChange={e => setFilters(f => ({ ...f, entityType: e.target.value }))} placeholder="VD: JOURNAL_ENTRY" />
          </div>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>ENTITY ID</label>
            <input className="input" style={{ width: '100%', fontSize: '13px' }} value={filters.entityId} onChange={e => setFilters(f => ({ ...f, entityId: e.target.value }))} placeholder="ID của đối tượng" />
          </div>
          <button type="button" className="btn btn-primary" onClick={loadData} disabled={loading} style={{ padding: '9px 16px', fontSize: '12.5px', whiteSpace: 'nowrap' }}>Truy vấn</button>
          <button type="button" className="btn btn-outline" onClick={handleReset} style={{ padding: '9px 16px', fontSize: '12.5px', whiteSpace: 'nowrap' }}>Xóa lọc</button>
        </div>
      </div>

      {/* Ô tìm kiếm nhanh trên kết quả */}
      <div style={{ position: 'relative', marginBottom: '14px' }}>
        <Search size={15} style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--text-muted)' }} />
        <input
          type="text"
          className="input"
          placeholder="Tìm nhanh trong kết quả: eventType, entityId, cán bộ, mô tả..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          style={{ paddingLeft: '32px', width: '100%', fontSize: '13px' }}
        />
      </div>

      {/* Table */}
      {filteredLogs.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 24px', color: 'var(--text-muted)' }}>
          <ScrollText size={48} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
          <p style={{ fontWeight: 600, fontSize: '15px' }}>Không có bản ghi kiểm toán nào khớp</p>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', fontSize: '12.5px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--bg-light)', borderBottom: '2px solid var(--border-color)', textAlign: 'left' }}>
                <th style={{ padding: '10px' }}>THỜI ĐIỂM</th>
                <th style={{ padding: '10px' }}>EVENT TYPE</th>
                <th style={{ padding: '10px' }}>ĐỐI TƯỢNG</th>
                <th style={{ padding: '10px' }}>CÁN BỘ THỰC HIỆN</th>
                <th style={{ padding: '10px' }}>DỊCH VỤ / CHI NHÁNH</th>
                <th style={{ padding: '10px' }}>CORRELATION ID</th>
                <th style={{ padding: '10px' }}>MÔ TẢ</th>
              </tr>
            </thead>
            <tbody>
              {filteredLogs.map((item) => (
                <tr key={item.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '10px', fontSize: '11.5px', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                    {item.performedAt ? formatDateVi(item.performedAt) : '—'}
                  </td>
                  <td style={{ padding: '10px' }}>
                    <span style={{ padding: '2px 8px', borderRadius: '5px', fontSize: '11px', fontWeight: 700, background: '#eff6ff', color: '#1d4ed8', fontFamily: 'monospace' }}>
                      {item.eventType}
                    </span>
                  </td>
                  <td style={{ padding: '10px', fontSize: '11.5px' }}>
                    <div style={{ fontWeight: 700, fontFamily: 'monospace', color: 'var(--primary-navy)' }}>{item.entityType}</div>
                    <div style={{ fontFamily: 'monospace', color: 'var(--text-muted)' }}>{item.entityId.length > 20 ? `${item.entityId.slice(0, 20)}…` : item.entityId}</div>
                  </td>
                  <td style={{ padding: '10px', fontSize: '11.5px' }}>
                    <div style={{ fontFamily: 'monospace' }}>{item.performedBy || 'hệ thống'}</div>
                    {item.actorRole && <div style={{ color: 'var(--text-muted)', fontSize: '10.5px' }}>{item.actorRole}</div>}
                  </td>
                  <td style={{ padding: '10px', fontSize: '11.5px', color: 'var(--text-muted)' }}>
                    <div>{item.serviceName}</div>
                    {item.branchId && <div style={{ fontSize: '10.5px' }}>{item.branchId}</div>}
                  </td>
                  <td style={{ padding: '10px', fontFamily: 'monospace', fontSize: '11px', color: 'var(--text-muted)' }}>
                    {item.correlationId ? (item.correlationId.length > 14 ? `${item.correlationId.slice(0, 14)}…` : item.correlationId) : '—'}
                  </td>
                  <td style={{ padding: '10px', fontSize: '12px', maxWidth: '280px' }}>{item.description || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <p style={{ fontSize: '11.5px', color: 'var(--text-muted)', marginTop: '10px' }}>
        Hiển thị {filteredLogs.length} / {logs.length} bản ghi (giới hạn 500 bản ghi gần nhất mỗi truy vấn từ ledger-service).
      </p>
    </div>
  );
}
