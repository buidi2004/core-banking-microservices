import React, { useState, useEffect } from 'react';
import { LoggedInStaff, KycApplication } from '../types';
import { ApiService } from '../api';
import { CheckCircle2, XCircle, RefreshCw, AlertCircle, ShieldCheck, UserCheck, Eye, FileText, Image as ImageIcon, Download } from 'lucide-react';

interface KycManagementProps {
  currentStaff: LoggedInStaff;
  onRefresh?: () => void;
}

export function KycManagement({ currentStaff, onRefresh }: KycManagementProps) {
  const [kycs, setKycs] = useState<KycApplication[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [selectedKyc, setSelectedKyc] = useState<KycApplication | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await ApiService.fetchPendingKyc(currentStaff);
      setKycs(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleReview = async (kycId: string, status: 'APPROVED' | 'REJECTED') => {
    let reason: string | undefined;
    if (status === 'REJECTED') {
      const inputReason = window.prompt(
        'Nhập lý do từ chối hồ sơ eKYC (ví dụ: Ảnh CCCD bị mờ / Chân dung không khớp):',
        'Ảnh giấy tờ tùy thân không rõ thông tin bảo mật'
      );
      if (!inputReason) return;
      reason = inputReason;
    } else {
      if (!window.confirm(`Xác nhận phê duyệt hồ sơ eKYC ${kycId}? Người dùng sẽ được nâng cấp hạn mức giao dịch.`)) {
        return;
      }
    }

    setActionLoadingId(kycId);
    setActionMessage(null);

    const result = await ApiService.reviewKyc(currentStaff, kycId, status, reason);
    setActionLoadingId(null);

    if (result.success) {
      setActionMessage({
        type: 'success',
        text: status === 'APPROVED'
          ? `✅ Phê duyệt thành công hồ sơ eKYC ${kycId}! Hạn mức người dùng đã được kích hoạt.`
          : `ℹ️ Đã từ chối hồ sơ eKYC ${kycId}.`
      });
      loadData();
      if (onRefresh) onRefresh();
    } else {
      setActionMessage({ type: 'error', text: `❌ ${result.message}` });
    }
  };

  const handleExportKycCsv = () => {
    if (kycs.length === 0) {
      alert('Không có hồ sơ eKYC để xuất CSV');
      return;
    }
    const bom = '\ufeff';
    const header = 'STT,Mã Hồ Sơ,Mã Khách Hàng,Loại Giấy Tờ,Số Giấy Tờ (CCCD),Trạng Thái,Cấp Độ KYC,Thời Gian Tạo\n';
    const rows = kycs.map((k, idx) =>
      `${idx + 1},"${k.id}","${k.userId}","${k.documentType}","${k.documentNumber || ''}","${k.verificationStatus}","${k.currentKycTier || 'TIER_1'}","${k.createdAt || ''}"`
    ).join('\n');
    const blob = new Blob([bom + header + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bao_cao_ekyc_${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  return (
    <div className="card" style={{ padding: '24px' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-navy)', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ShieldCheck size={20} color="var(--primary-blue)" />
            QUẢN TRỊ &amp; DUYỆT HỒ SƠ eKYC (XÁC THỰC DANH TÍNH SỐ)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Kiểm duyệt CCCD gắn chip và đối chiếu ảnh chân dung sinh trắc học theo chuẩn NHNN
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button
            type="button"
            className="btn btn-outline"
            onClick={handleExportKycCsv}
            disabled={loading || kycs.length === 0}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px', color: 'var(--primary-blue)' }}
          >
            <Download size={14} />
            Xuất Báo Cáo eKYC (CSV)
          </button>
          <button
            type="button"
            className="btn btn-outline"
            onClick={loadData}
            disabled={loading}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}
          >
            <RefreshCw size={14} className={loading ? 'spin' : ''} />
            Làm mới
          </button>
        </div>
      </div>

      {/* KPI Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '18px' }}>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>HỒ SƠ CHỜ DUYỆT</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: '#f59e0b', marginTop: '4px' }}>
            {kycs.length} hồ sơ
          </div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>LOẠI GIẤY TỜ</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--primary-navy)', marginTop: '4px' }}>
            CCCD Gắn Chip / Hộ Chiếu
          </div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>CẤP BẬC DUYỆT</div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: 'var(--success-green)', marginTop: '4px' }}>
            TIER 2 (VERIFIED)
          </div>
        </div>
      </div>

      {/* Notification Banner */}
      {actionMessage && (
        <div style={{
          padding: '12px 16px',
          borderRadius: '8px',
          marginBottom: '16px',
          background: actionMessage.type === 'success' ? '#ecfdf5' : '#fef2f2',
          border: `1px solid ${actionMessage.type === 'success' ? '#10b981' : '#ef4444'}`,
          color: actionMessage.type === 'success' ? '#065f46' : '#991b1b',
          fontSize: '13px',
          fontWeight: 600,
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
        }}>
          {actionMessage.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
          {actionMessage.text}
        </div>
      )}

      {/* Table */}
      {kycs.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 24px', color: 'var(--text-muted)' }}>
          <UserCheck size={48} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
          <p style={{ fontWeight: 600, fontSize: '15px' }}>Không có hồ sơ eKYC nào đang chờ duyệt</p>
          <p style={{ fontSize: '12px', marginTop: '4px' }}>Mọi yêu cầu xác minh danh tính khách hàng đã được kiểm duyệt đầy đủ.</p>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', fontSize: '13px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--bg-light)', borderBottom: '2px solid var(--border-color)', textAlign: 'left' }}>
                <th style={{ padding: '10px' }}>MÃ EKYC</th>
                <th style={{ padding: '10px' }}>USER ID</th>
                <th style={{ padding: '10px' }}>LOẠI GIẤY TỜ</th>
                <th style={{ padding: '10px' }}>SỐ GIẤY TỜ</th>
                <th style={{ padding: '10px' }}>HÌNH ẢNH</th>
                <th style={{ padding: '10px' }}>THỜI GIAN GỬI</th>
                <th style={{ padding: '10px', textAlign: 'center' }}>THAO TÁC</th>
              </tr>
            </thead>
            <tbody>
              {kycs.map((kyc) => (
                <tr key={kyc.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '12px 10px', fontFamily: 'monospace', fontWeight: 600 }}>
                    {kyc.id.substring(0, 8)}...
                  </td>
                  <td style={{ padding: '12px 10px' }}>
                    <div style={{ fontWeight: 600 }}>{kyc.userId}</div>
                    <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Cấp: {kyc.currentKycTier || 'BASIC'}</span>
                  </td>
                  <td style={{ padding: '12px 10px' }}>
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '4px',
                      fontSize: '11px',
                      fontWeight: 700,
                      background: '#e0f2fe',
                      color: '#0369a1',
                    }}>
                      {kyc.documentType || 'CCCD'}
                    </span>
                  </td>
                  <td style={{ padding: '12px 10px', fontWeight: 700, letterSpacing: '0.5px' }}>
                    {kyc.documentNumber || 'N/A'}
                  </td>
                  <td style={{ padding: '12px 10px' }}>
                    <button
                      type="button"
                      className="btn btn-outline"
                      onClick={() => setSelectedKyc(kyc)}
                      style={{ padding: '4px 8px', fontSize: '11px', gap: '4px' }}
                    >
                      <Eye size={12} />
                      Xem chi tiết
                    </button>
                  </td>
                  <td style={{ padding: '12px 10px', color: 'var(--text-muted)', fontSize: '12px' }}>
                    {new Date(kyc.createdAt).toLocaleString('vi-VN')}
                  </td>
                  <td style={{ padding: '12px 10px', textAlign: 'center' }}>
                    <div style={{ display: 'flex', gap: '6px', justifyContent: 'center' }}>
                      <button
                        type="button"
                        className="btn btn-primary"
                        onClick={() => handleReview(kyc.id, 'APPROVED')}
                        disabled={actionLoadingId === kyc.id}
                        style={{ padding: '6px 12px', fontSize: '12px', gap: '4px', background: '#059669', borderColor: '#059669' }}
                      >
                        <CheckCircle2 size={13} />
                        Duyệt
                      </button>
                      <button
                        type="button"
                        className="btn btn-outline"
                        onClick={() => handleReview(kyc.id, 'REJECTED')}
                        disabled={actionLoadingId === kyc.id}
                        style={{ padding: '6px 12px', fontSize: '12px', gap: '4px', color: '#dc2626', borderColor: '#fca5a5' }}
                      >
                        <XCircle size={13} />
                        Từ chối
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Detail View */}
      {selectedKyc && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0,0,0,0.6)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 9999,
          padding: '20px',
        }}>
          <div style={{
            background: '#fff',
            borderRadius: '16px',
            maxWidth: '650px',
            width: '100%',
            padding: '24px',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.2)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '16px', fontWeight: 800, color: 'var(--primary-navy)' }}>
                Chi Tiết Hồ Sơ eKYC #{selectedKyc.id.substring(0, 8)}
              </h3>
              <button
                type="button"
                onClick={() => setSelectedKyc(null)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: '18px', fontWeight: 'bold' }}
              >
                ✕
              </button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px', fontSize: '13px' }}>
              <div><strong>User ID:</strong> {selectedKyc.userId}</div>
              <div><strong>Loại giấy tờ:</strong> {selectedKyc.documentType}</div>
              <div><strong>Số CCCD/Hộ chiếu:</strong> {selectedKyc.documentNumber}</div>
              <div><strong>Thời gian gửi:</strong> {new Date(selectedKyc.createdAt).toLocaleString('vi-VN')}</div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px', marginBottom: '20px' }}>
              <div style={{ border: '1px solid var(--border-color)', borderRadius: '8px', padding: '10px', textAlign: 'center' }}>
                <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--text-muted)', marginBottom: '6px' }}>MẶT TRƯỚC CCCD</div>
                {selectedKyc.frontImageUrl ? (
                  <img src={selectedKyc.frontImageUrl} alt="Front" style={{ width: '100%', height: '110px', objectFit: 'cover', borderRadius: '4px' }} />
                ) : (
                  <div style={{ height: '110px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', color: '#94a3b8' }}>
                    <ImageIcon size={32} />
                  </div>
                )}
              </div>
              <div style={{ border: '1px solid var(--border-color)', borderRadius: '8px', padding: '10px', textAlign: 'center' }}>
                <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--text-muted)', marginBottom: '6px' }}>MẶT SAU CCCD</div>
                {selectedKyc.backImageUrl ? (
                  <img src={selectedKyc.backImageUrl} alt="Back" style={{ width: '100%', height: '110px', objectFit: 'cover', borderRadius: '4px' }} />
                ) : (
                  <div style={{ height: '110px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', color: '#94a3b8' }}>
                    <ImageIcon size={32} />
                  </div>
                )}
              </div>
              <div style={{ border: '1px solid var(--border-color)', borderRadius: '8px', padding: '10px', textAlign: 'center' }}>
                <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--text-muted)', marginBottom: '6px' }}>ẢNH CHÂN DUNG</div>
                {selectedKyc.faceImageUrl ? (
                  <img src={selectedKyc.faceImageUrl} alt="Face" style={{ width: '100%', height: '110px', objectFit: 'cover', borderRadius: '4px' }} />
                ) : (
                  <div style={{ height: '110px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', color: '#94a3b8' }}>
                    <ImageIcon size={32} />
                  </div>
                )}
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
              <button
                type="button"
                className="btn btn-outline"
                onClick={() => setSelectedKyc(null)}
              >
                Đóng
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => {
                  const id = selectedKyc.id;
                  setSelectedKyc(null);
                  handleReview(id, 'APPROVED');
                }}
                style={{ background: '#059669', borderColor: '#059669' }}
              >
                Phê duyệt eKYC
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

