import React, { useState, useEffect } from 'react';
import { LoggedInStaff, AdminSavingsAccount } from '../types';
import { ApiService } from '../api';
import { formatCurrency } from '../utils';
import { PiggyBank, RefreshCw, Search, CheckCircle2, Clock, Calendar, TrendingUp, Download } from 'lucide-react';

interface SavingsManagementProps {
  currentStaff: LoggedInStaff;
  onRefresh?: () => void;
}

export function SavingsManagement({ currentStaff, onRefresh }: SavingsManagementProps) {
  const [savingsList, setSavingsList] = useState<AdminSavingsAccount[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'SETTLED'>('ALL');

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await ApiService.fetchAdminSavings(currentStaff);
      setSavingsList(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const filteredList = savingsList.filter(item => {
    const matchStatus = statusFilter === 'ALL' || item.status === statusFilter;
    const matchSearch = searchTerm === '' ||
      item.accountNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.userId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.productName.toLowerCase().includes(searchTerm.toLowerCase());
    return matchStatus && matchSearch;
  });

  const totalPrincipal = savingsList.reduce((sum, item) => sum + (item.principal || 0), 0);
  const activePrincipal = savingsList
    .filter(item => item.status === 'ACTIVE')
    .reduce((sum, item) => sum + (item.principal || 0), 0);
  const activeCount = savingsList.filter(item => item.status === 'ACTIVE').length;
  const settledCount = savingsList.filter(item => item.status === 'SETTLED').length;

  const handleExportSavingsReport = () => {
    const now = new Date().toISOString().split('T')[0];
    const headers = '\ufeffSố Tài Khoản Tiết Kiệm,Mã Khách Hàng,Tên Sản Phẩm,Số Tiền Gốc (VND),Lãi Suất (%/năm),Kỳ Hạn (Tháng),Trạng Thái,Ngày Bắt Đầu,Ngày Đáo Hạn\n';
    const rows = filteredList.map(s =>
      `"${s.accountNumber}","${s.userId}","${s.productName}",${s.principal},${s.interestRate},${s.termMonths},"${s.status}","${s.startDate}","${s.maturityDate}"`
    ).join('\n');

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `danh-muc-huy-dong-tiet-kiem-${now}.csv`;
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
            <PiggyBank size={20} color="var(--primary-blue)" />
            QUẢN LÝ TIỀN GỬI TIẾT KIỆM TOÀN HỆ THỐNG (CORE SAVINGS)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Theo dõi danh mục huy động vốn dân cư, kỳ hạn lãi suất và trạng thái tất toán các sổ tiết kiệm
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button
            type="button"
            className="btn btn-outline"
            onClick={handleExportSavingsReport}
            style={{ padding: '6px 14px', fontSize: '12px', gap: '6px' }}
          >
            <Download size={14} />
            <span>Xuất Danh Mục Tiết Kiệm (CSV)</span>
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

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '18px' }}>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>TỔNG HUY ĐỘNG VỐN</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--primary-blue)', marginTop: '4px' }}>
            {formatCurrency(totalPrincipal)}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Toàn bộ danh mục</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>SỐ DƯ ĐANG HOẠT ĐỘNG</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--success-green)', marginTop: '4px' }}>
            {formatCurrency(activePrincipal)}
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>{activeCount} sổ đang sinh lãi</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>SỔ ĐÃ TẤT TOÁN</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: 'var(--text-muted)', marginTop: '4px' }}>
            {settledCount} sổ
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Đã hoàn gốc + lãi</div>
        </div>
        <div style={{ background: 'var(--bg-light)', padding: '14px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 600 }}>LÃI SUẤT BÌNH QUÂN</div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: '#f59e0b', marginTop: '4px' }}>
            5.8% - 7.2%
          </div>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>Kỳ hạn 1 - 24 tháng</div>
        </div>
      </div>

      {/* Filters Bar */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1 }}>
          <Search size={15} style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--text-muted)' }} />
          <input
            type="text"
            className="input"
            placeholder="Tìm theo số sổ TK, mã User hoặc gói tiết kiệm..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ paddingLeft: '32px', width: '100%', fontSize: '13px' }}
          />
        </div>
        <div style={{ display: 'flex', gap: '6px' }}>
          {(['ALL', 'ACTIVE', 'SETTLED'] as const).map(tab => (
            <button
              key={tab}
              type="button"
              className={`btn ${statusFilter === tab ? 'btn-primary' : 'btn-outline'}`}
              onClick={() => setStatusFilter(tab)}
              style={{ padding: '6px 12px', fontSize: '12px' }}
            >
              {tab === 'ALL' ? 'Tất cả' : tab === 'ACTIVE' ? 'Đang hiệu lực' : 'Đã tất toán'}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      {filteredList.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 24px', color: 'var(--text-muted)' }}>
          <PiggyBank size={48} color="#cbd5e1" style={{ margin: '0 auto 12px' }} />
          <p style={{ fontWeight: 600, fontSize: '15px' }}>Không tìm thấy sổ tiết kiệm nào</p>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table" style={{ width: '100%', fontSize: '13px', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--bg-light)', borderBottom: '2px solid var(--border-color)', textAlign: 'left' }}>
                <th style={{ padding: '10px' }}>SỐ SỔ TIẾT KIỆM</th>
                <th style={{ padding: '10px' }}>USER ID</th>
                <th style={{ padding: '10px' }}>GÓI SẢN PHẨM</th>
                <th style={{ padding: '10px', textAlign: 'right' }}>GỐC TIỀN GỬI</th>
                <th style={{ padding: '10px', textAlign: 'center' }}>KỲ HẠN / LÃI SUẤT</th>
                <th style={{ padding: '10px', textAlign: 'right' }}>LÃI DỰ KIẾN</th>
                <th style={{ padding: '10px' }}>NGÀY GỬI & ĐÁO HẠN</th>
                <th style={{ padding: '10px', textAlign: 'center' }}>TRẠNG THÁI</th>
              </tr>
            </thead>
            <tbody>
              {filteredList.map((item) => {
                const isActive = item.status === 'ACTIVE';
                return (
                  <tr key={item.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '12px 10px', fontWeight: 700, fontFamily: 'monospace', color: 'var(--primary-navy)' }}>
                      {item.accountNumber}
                    </td>
                    <td style={{ padding: '12px 10px', color: 'var(--text-muted)', fontSize: '12px' }}>
                      {item.userId}
                    </td>
                    <td style={{ padding: '12px 10px' }}>
                      <div style={{ fontWeight: 600 }}>{item.productName}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{item.rolloverType}</div>
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'right', fontWeight: 800, color: 'var(--primary-blue)' }}>
                      {formatCurrency(item.principal)}
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'center' }}>
                      <span style={{
                        padding: '2px 8px',
                        borderRadius: '4px',
                        fontSize: '11px',
                        fontWeight: 700,
                        background: '#e0f2fe',
                        color: '#0369a1',
                      }}>
                        {item.termMonths} tháng @ {item.interestRate}%
                      </span>
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'right', fontWeight: 600, color: 'var(--success-green)' }}>
                      {formatCurrency(item.expectedInterest || 0)}
                    </td>
                    <td style={{ padding: '12px 10px', fontSize: '11.5px', color: 'var(--text-muted)' }}>
                      <div>Từ: {item.startDate}</div>
                      <div>Đến: {item.maturityDate}</div>
                    </td>
                    <td style={{ padding: '12px 10px', textAlign: 'center' }}>
                      <span style={{
                        padding: '4px 8px',
                        borderRadius: '6px',
                        fontSize: '11px',
                        fontWeight: 700,
                        background: isActive ? '#ecfdf5' : '#f1f5f9',
                        color: isActive ? '#065f46' : '#64748b',
                        border: `1px solid ${isActive ? '#a7f3d0' : '#cbd5e1'}`,
                      }}>
                        {isActive ? 'ĐANG HIỆU LỰC' : 'ĐÃ TẤT TOÁN'}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

