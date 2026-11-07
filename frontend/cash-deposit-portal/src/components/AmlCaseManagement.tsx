import React, { useState, useEffect } from 'react';
import { LoggedInStaff, AmlCase, AmlCaseStatus, AmlCaseEvent, CreateAmlCasePayload } from '../types';
import { ApiService } from '../api';
import { formatDateVi } from '../utils';
import { ShieldAlert, RefreshCw, Search, Plus, History, Lock, Unlock, X, UserCheck, PlayCircle, FolderMinus } from 'lucide-react';

interface AmlCaseManagementProps {
  currentStaff: LoggedInStaff;
  onRefresh?: () => void;
}

const STATUS_META: Record<AmlCaseStatus, { label: string; bg: string; color: string; border: string }> = {
  OPEN: { label: 'MỚI PHÁT HIỆN', bg: '#eff6ff', color: '#1d4ed8', border: '#bfdbfe' },
  ASSIGNED: { label: 'ĐÃ PHÂN CÔNG', bg: '#eef2ff', color: '#4338ca', border: '#c7d2fe' },
  INVESTIGATING: { label: 'ĐANG ĐIỀU TRA', bg: '#fffbeb', color: '#b45309', border: '#fde68a' },
  FROZEN: { label: 'VÍ BỊ ĐÓNG BĂNG', bg: '#fef2f2', color: '#b91c1c', border: '#fecaca' },
  RELEASED: { label: 'ĐÃ GỠ PHONG TỎA', bg: '#ecfdf5', color: '#047857', border: '#a7f3d0' },
  CLOSED: { label: 'ĐÃ ĐÓNG', bg: '#f1f5f9', color: '#475569', border: '#cbd5e1' },
};

// Bản đồ chuyển trạng thái khớp với AmlCaseService.allowedTransitions() phía backend
const ALLOWED_TRANSITIONS: Record<AmlCaseStatus, AmlCaseStatus[]> = {
  OPEN: ['INVESTIGATING', 'FROZEN'],
  ASSIGNED: ['INVESTIGATING', 'FROZEN'],
  INVESTIGATING: ['FROZEN', 'RELEASED', 'CLOSED'],
  FROZEN: ['RELEASED', 'CLOSED'],
  RELEASED: ['CLOSED'],
  CLOSED: [],
};

const ACTION_META: Partial<Record<AmlCaseStatus, { label: string; icon: React.ReactNode; danger?: boolean }>> = {
  INVESTIGATING: { label: 'Bắt đầu điều tra', icon: <PlayCircle size={13} /> },
  FROZEN: { label: 'Đóng băng ví', icon: <Lock size={13} />, danger: true },
  RELEASED: { label: 'Gỡ phong tỏa ví', icon: <Unlock size={13} /> },
  CLOSED: { label: 'Đóng hồ sơ', icon: <FolderMinus size={13} /> },
};

type ModalAction = { kind: 'assign' } | { kind: 'status'; next: AmlCaseStatus } | { kind: 'events'; events: AmlCaseEvent[]; caseId: string };

export function AmlCaseManagement({ currentStaff, onRefresh }: AmlCaseManagementProps) {
  const [cases, setCases] = useState<AmlCase[]>([]);
  const [loading, setLoading] = useState(false);
  const [statusFilter, setStatusFilter] = useState<'ALL' | AmlCaseStatus>('ALL');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [modal, setModal] = useState<ModalAction | null>(null);
  const [modalCase, setModalCase] = useState<AmlCase | null>(null);
  const [reason, setReason] = useState('');
  const [assigneeId, setAssigneeId] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [notice, setNotice] = useState<{ ok: boolean; text: string } | null>(null);
  const [createPayload, setCreatePayload] = useState<CreateAmlCasePayload>({ transactionId: '', customerId: '', reason: '', slaHours: 24 });

  const isManager = currentStaff.role === 'MANAGER';

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await ApiService.fetchAmlCases(currentStaff, statusFilter === 'ALL' ? undefined : statusFilter);
      setCases(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isManager) void loadData();
  }, [statusFilter]);

  const openAction = (item: AmlCase, action: ModalAction) => {
    setModalCase(item);
    setModal(action);
    setReason('');
    setAssigneeId(item.assignedTo || '');
    setNotice(null);
  };

  const handleSubmit = async () => {
    if (!modalCase || !modal || modal.kind === 'events') return;
    if (!reason.trim()) {
      setNotice({ ok: false, text: 'Vui lòng nhập lý do (bắt buộc theo quy trình PCRT).' });
      return;
    }
    setSubmitting(true);
    try {
      const res = modal.kind === 'assign'
        ? await ApiService.assignAmlCase(currentStaff, modalCase.id, assigneeId.trim(), reason.trim())
        : await ApiService.updateAmlCaseStatus(currentStaff, modalCase.id, modal.next, reason.trim());
      if (res.success) {
        setNotice({ ok: true, text: modal.kind === 'assign' ? 'Đã phân công điều tra viên.' : `Đã chuyển hồ sơ sang ${STATUS_META[modal.next as AmlCaseStatus]?.label || modal.next}.` });
        setModal(null);
        await loadData();
        onRefresh?.();
      } else {
        setNotice({ ok: false, text: res.message || 'Thao tác không thành công.' });
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleViewEvents = async (item: AmlCase) => {
    const events = await ApiService.fetchAmlCaseEvents(currentStaff, item.id);
    openAction(item, { kind: 'events', events, caseId: item.id });
  };

  const handleCreate = async () => {
    if (!createPayload.transactionId.trim() || !createPayload.reason.trim()) {
      setNotice({ ok: false, text: 'Mã giao dịch và lý do mở hồ sơ là bắt buộc.' });
      return;
    }
    setSubmitting(true);
    try {
      const res = await ApiService.createAmlCase(currentStaff, {
        ...createPayload,
        transactionId: createPayload.transactionId.trim(),
        customerId: (createPayload.customerId || '').trim() || undefined,
        reason: createPayload.reason.trim(),
      });
      if (res.success) {
        setNotice({ ok: true, text: 'Đã mở hồ sơ AML mới.' });
        setShowCreate(false);
        setCreatePayload({ transactionId: '', customerId: '', reason: '', slaHours: 24 });
        await loadData();
      } else {
        setNotice({ ok: false, text: res.message || 'Không thể tạo hồ sơ AML.' });
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleExportCsv = () => {
    const now = new Date().toISOString().split('T')[0];
    const headers = '\ufeffMã Hồ Sơ,Mã Giao Dịch,Mã Khách Hàng,Trạng Thái,Điều Tra Viên,Lý Do,Hạn SLA,Tạo Lúc,Cập Nhật\n';
    const rows = filteredCases.map(c =>
      `"${c.id}","${c.transactionId}","${c.customerId || ''}","${c.status}","${c.assignedTo || ''}","${(c.reason || '').replace(/"/g, '""')}","${c.slaDueAt || ''}","${c.createdAt || ''}","${c.updatedAt || ''}"`
    ).join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `ho-so-aml-pcrt-${now}.csv`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  const filteredCases = cases.filter(item => {
    const matchStatus = statusFilter === 'ALL' || item.status === statusFilter;
    const q = searchTerm.toLowerCase();
    const matchSearch = q === '' ||
      item.transactionId.toLowerCase().includes(q) ||
      (item.customerId || '').toLowerCase().includes(q) ||
      (item.assignedTo || '').toLowerCase().includes(q);
    return matchStatus && matchSearch;
  });

  const openCount = cases.filter(c => c.status !== 'CLOSED').length;
  const frozenCount = cases.filter(c => c.status === 'FROZEN').length;
  const nowIso = Date.now();
  const overdueCount = cases.filter(c => c.status !== 'CLOSED' && c.slaDueAt && new Date(c.slaDueAt).getTime() < nowIso).length;

  if (!isManager) {
    return (
      <div className="card" style={{ padding: '32px', textAlign: 'center' }}>
        <ShieldAlert size={44} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
        <h2 style={{ fontSize: '16px', fontWeight: 800, color: 'var(--primary-navy)' }}>Chức năng dành cho Quản lý / Tuân thủ</h2>
        <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '6px' }}>
          Quản lý hồ sơ AML (Luật PCRT 2022) chỉ dành cho Kiểm soát viên, Quản trị viên hoặc Cán bộ tuân thủ.
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
            <ShieldAlert size={20} color="#dc2626" />
            QUẢN LÝ HỒ SƠ AML — PHÒNG CHỐNG RỬA TIỀN (PCRT 2022)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Theo dõi hồ sơ nghi vấn, phân công điều tra, đóng băng/gỡ phong tỏa ví và kiểm soát hạn SLA xử lý
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button type="button" className="btn btn-outline" onClick={handleExportCsv} style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}>
            <History size={14} />
            <span>Xuất CSV</span>
          </button>
          <button type="button" className="btn btn-primary" onClick={() => setShowCreate(v => !v)} style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}>
            <Plus size={14} />
            <span>Mở Hồ Sơ AML</span>
          </button>
          <button type="button" className="btn btn-outline" onClick={loadData} disabled={loading} style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}>
            <RefreshCw size={14} className={loading ? 'spin' : ''} />
            Làm mới
          </button>
        </div>
      </div>

      {notice && (
        <div style={{ padding: '10px 14px', borderRadius: '8px', marginBottom: '14px', fontSize: '13px', fontWeight: 600, background: notice.ok ? '#ecfdf5' : '#fef2f2', color: notice.ok ? '#065f46' : '#b91c1c', border: `1px solid ${notice.ok ? '#a7f3d0' : '#fecaca'}` }}>
          {notice.text}
        </div>
      )}

      {/* Form tạo hồ sơ mới */}
      {showCreate && (
        <div style={{ background: 'var(--bg-light)', border: '1px solid var(--border-color)', borderRadius: '10px', padding: '16px', marginBottom: '16px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 2fr 3fr 1fr auto', gap: '10px', alignItems: 'end' }}>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>MÃ GIAO DỊCH NGHI VẤN *</label>
              <input className="input" style={{ width: '100%', fontSize: '13px' }} value={createPayload.transactionId} onChange={e => setCreatePayload(p => ({ ...p, transactionId: e.target.value }))} placeholder="transactionId (UUID)" />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>MÃ KHÁCH HÀNG</label>
              <input className="input" style={{ width: '100%', fontSize: '13px' }} value={createPayload.customerId} onChange={e => setCreatePayload(p => ({ ...p, customerId: e.target.value }))} placeholder="userId (tùy chọn)" />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>LÝ DO NGHI VẤN *</label>
              <input className="input" style={{ width: '100%', fontSize: '13px' }} value={createPayload.reason} onChange={e => setCreatePayload(p => ({ ...p, reason: e.target.value }))} placeholder="Ví dụ: Giao dịch bất thường vượt ngưỡng báo cáo" />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)' }}>SLA (GIỜ)</label>
              <input className="input" style={{ width: '100%', fontSize: '13px' }} type="number" min={1} max={720} value={createPayload.slaHours} onChange={e => setCreatePayload(p => ({ ...p, slaHours: Number(e.target.value) || 24 }))} />
            </div>
            <button type="button" className="btn btn-primary" onClick={handleCreate} disabled={submitting} style={{ padding: '9px 18px', fontSize: '12.5px', whiteSpace: 'nowrap' }}>
              {submitting ? 'Đang lưu...' : 'Tạo hồ sơ'}
            </button>
          </div>
        </div>
      )}

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '18px' }}>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>TỔNG HỒ SƠ</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-blue)', marginTop: '4px' }}>{cases.length}</div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Toàn hệ thống</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>ĐANG XỬ LÝ</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: '#b45309', marginTop: '4px' }}>{openCount}</div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Chưa đóng hồ sơ</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>VÍ BỊ ĐÓNG BĂNG</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: '#b91c1c', marginTop: '4px' }}>{frozenCount}</div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Phong tỏa chờ kết luận</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>QUÁ HẠN SLA</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: overdueCount > 0 ? '#b91c1c' : 'var(--success-green)', marginTop: '4px' }}>{overdueCount}</div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Vượt hạn xử lý quy định</div>
        </div>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1 }}>
          <Search size={15} style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--text-muted)' }} />
          <input
            type="text"
            className="input"
            placeholder="Tìm theo mã giao dịch, mã khách hàng hoặc điều tra viên..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ paddingLeft: '32px', width: '100%', fontSize: '13px' }}
          />
        </div>
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          {(['ALL', 'OPEN', 'INVESTIGATING', 'FROZEN', 'CLOSED'] as const).map(tab => (
            <button
              key={tab}
              type="button"
              className={`btn ${statusFilter === tab ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setStatusFilter(tab)}
              style={{ padding: '6px 12px', fontSize: '12px' }}
            >
              {tab === 'ALL' ? 'Tất cả' : STATUS_META[tab].label}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      {filteredCases.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 24px', color: 'var(--text-muted)' }}>
          <ShieldAlert size={48} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
          <p style={{ fontWeight: 600, fontSize: '15px' }}>Không có hồ sơ AML nào</p>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', fontSize: '13px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--bg-light)', borderBottom: '2px solid var(--border-color)', textAlign: 'left' }}>
                <th style={{ padding: '10px' }}>MÃ GIAO DỊCH</th>
                <th style={{ padding: '10px' }}>KHÁCH HÀNG</th>
                <th style={{ padding: '10px' }}>LÝ DO NGHI VẤN</th>
                <th style={{ padding: '10px' }}>ĐIỀU TRA VIÊN</th>
                <th style={{ padding: '10px' }}>HẠN SLA</th>
                <th style={{ padding: '10px', textAlign: 'center' }}>TRẠNG THÁI</th>
                <th style={{ padding: '10px', textAlign: 'center' }}>THAO TÁC</th>
              </tr>
            </thead>
            <tbody>
              {filteredCases.map((item) => {
                const meta = STATUS_META[item.status] || STATUS_META.CLOSED;
                const overdue = item.status !== 'CLOSED' && item.slaDueAt && new Date(item.slaDueAt).getTime() < Date.now();
                const transitions = ALLOWED_TRANSITIONS[item.status] || [];
                return (
                  <tr key={item.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '12px 10px', fontWeight: 700, fontFamily: 'monospace', fontSize: '12px', color: 'var(--primary-navy)' }}>
                      {item.transactionId.length > 18 ? `${item.transactionId.slice(0, 18)}…` : item.transactionId}
                    </td>
                    <td style={{ padding: '12px 10px', fontFamily: 'monospace', fontSize: '12px', color: 'var(--text-muted)' }}>
                      {item.customerId || '—'}
                    </td>
                    <td style={{ padding: '12px 10px', fontSize: '12.5px', maxWidth: '260px' }}>{item.reason || '—'}</td>
                    <td style={{ padding: '12px 10px', fontSize: '12px' }}>{item.assignedTo || '—'}</td>
                    <td style={{ padding: '12px 10px', fontSize: '12px' }}>
                      {item.slaDueAt ? (
                        <span style={{ color: overdue ? '#b91c1c' : 'var(--text-muted)', fontWeight: overdue ? 800 : 400 }}>
                          {formatDateVi(item.slaDueAt)}{overdue ? ' ⚠ Quá hạn' : ''}
                        </span>
                      ) : '—'}
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'center' }}>
                      <span style={{ padding: '4px 8px', borderRadius: '6px', fontSize: '11px', fontWeight: 700, background: meta.bg, color: meta.color, border: `1px solid ${meta.border}` }}>
                        {meta.label}
                      </span>
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'center' }}>
                      <div style={{ display: 'flex', gap: '6px', justifyContent: 'center', flexWrap: 'wrap' }}>
                        {(item.status === 'OPEN' || item.status === 'ASSIGNED') && (
                          <button type="button" className="btn btn-outline" onClick={() => openAction(item, { kind: 'assign' })} style={{ padding: '4px 10px', fontSize: '11.5px', gap: '4px' }}>
                            <UserCheck size={13} /> Phân công
                          </button>
                        )}
                        {transitions.map(next => {
                          const actionMeta = ACTION_META[next];
                          if (!actionMeta) return null;
                          return (
                            <button
                              key={next}
                              type="button"
                              className={`btn ${actionMeta.danger ? 'btn-danger' : 'btn-outline'}`}
                              onClick={() => openAction(item, { kind: 'status', next })}
                              style={{ padding: '4px 10px', fontSize: '11.5px', gap: '4px' }}
                            >
                              {actionMeta.icon} {actionMeta.label}
                            </button>
                          );
                        })}
                        <button type="button" className="btn btn-outline" onClick={() => void handleViewEvents(item)} style={{ padding: '4px 10px', fontSize: '11.5px', gap: '4px' }}>
                          <History size={13} /> Lịch sử
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal thao tác */}
      {modal && modal.kind !== 'events' && modalCase && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }} onClick={() => setModal(null)}>
          <div className="card" style={{ width: '480px', maxWidth: '92vw', padding: '24px' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>
                {modal.kind === 'assign' ? 'Phân công điều tra viên' : `Chuyển trạng thái: ${ACTION_META[modal.next]?.label || modal.next}`}
              </h3>
              <button type="button" onClick={() => setModal(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}><X size={18} /></button>
            </div>
            <p style={{ fontSize: '12.5px', color: 'var(--text-muted)', marginBottom: '12px' }}>
              Hồ sơ giao dịch <b style={{ fontFamily: 'monospace' }}>{modalCase.transactionId}</b> — hiện tại: <b>{STATUS_META[modalCase.status]?.label}</b>
            </p>
            {modal.kind === 'assign' && (
              <div className="form-group">
                <label style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)' }}>MÃ ĐIỀU TRA VIÊN (ASSIGNEE ID) *</label>
                <input className="input" style={{ width: '100%', fontSize: '13px' }} value={assigneeId} onChange={e => setAssigneeId(e.target.value)} placeholder="userId của cán bộ tiếp nhận" />
              </div>
            )}
            <div className="form-group">
              <label style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-muted)' }}>LÝ DO (BẮT BUỘC, GHI NHẬN SỔ KIỂM TOÁN) *</label>
              <textarea className="input" style={{ width: '100%', fontSize: '13px', minHeight: '80px' }} value={reason} onChange={e => setReason(e.target.value)} placeholder="Nhập lý do / căn cứ pháp lý..." />
            </div>
            {modal.kind === 'status' && modal.next === 'FROZEN' && (
              <p style={{ fontSize: '12px', color: '#b91c1c', fontWeight: 600, background: '#fef2f2', padding: '8px 12px', borderRadius: '8px' }}>
                ⚠ Cảnh báo: Ví của khách hàng sẽ bị phong tỏa giao dịch ngay sau khi xác nhận.
              </p>
            )}
            {modal.kind === 'status' && modal.next === 'RELEASED' && (
              <p style={{ fontSize: '12px', color: '#065f46', fontWeight: 600, background: '#ecfdf5', padding: '8px 12px', borderRadius: '8px' }}>
                Ví của khách hàng sẽ được gỡ phong tỏa và hoạt động bình thường trở lại.
              </p>
            )}
            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '14px' }}>
              <button type="button" className="btn btn-outline" onClick={() => setModal(null)} style={{ padding: '8px 16px', fontSize: '12.5px' }}>Hủy</button>
              <button type="button" className="btn btn-primary" onClick={handleSubmit} disabled={submitting} style={{ padding: '8px 16px', fontSize: '12.5px' }}>
                {submitting ? 'Đang xử lý...' : 'Xác nhận'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal lịch sử */}
      {modal?.kind === 'events' && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }} onClick={() => setModal(null)}>
          <div className="card" style={{ width: '560px', maxWidth: '92vw', padding: '24px', maxHeight: '80vh', overflowY: 'auto' }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--primary-navy)' }}>Lịch sử xử lý hồ sơ AML</h3>
              <button type="button" onClick={() => setModal(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}><X size={18} /></button>
            </div>
            {modal.events.length === 0 ? (
              <p style={{ fontSize: '13px', color: 'var(--text-muted)' }}>Chưa có sự kiện nào được ghi nhận.</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {modal.events.map(ev => (
                  <div key={ev.id} style={{ borderLeft: '3px solid var(--primary-blue)', paddingLeft: '12px', padding: '2px 0' }}>
                    <div style={{ fontSize: '12.5px', fontWeight: 800, color: 'var(--primary-navy)' }}>{ev.action}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{ev.reason || '—'}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                      Bởi {ev.actorId || 'hệ thống'} • {ev.createdAt ? formatDateVi(ev.createdAt) : ''}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
