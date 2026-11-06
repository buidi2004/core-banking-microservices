import React, { useState, useEffect } from 'react';
import { LoggedInStaff, SupportTicket, TicketMessage } from '../types';
import { ApiService } from '../api';
import { Headphones, RefreshCw, Search, CheckCircle2, MessageSquare, Send, Clock, AlertCircle, ShieldAlert, Check, Download } from 'lucide-react';

interface SupportDeskManagementProps {
  currentStaff: LoggedInStaff;
  onRefresh?: () => void;
}

export function SupportDeskManagement({ currentStaff, onRefresh }: SupportDeskManagementProps) {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [selectedTicketId, setSelectedTicketId] = useState<string | null>(null);
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  const [messages, setMessages] = useState<TicketMessage[]>([]);
  const [replyText, setReplyText] = useState('');
  const [resolutionNote, setResolutionNote] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED'>('ALL');

  const loadTickets = async () => {
    setLoading(true);
    try {
      const data = await ApiService.fetchSupportTickets(currentStaff);
      setTickets(data);
      if (data.length > 0 && !selectedTicketId) {
        selectTicket(data[0].id);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const selectTicket = async (ticketId: string) => {
    setSelectedTicketId(ticketId);
    try {
      const detail = await ApiService.fetchTicketDetail(currentStaff, ticketId);
      if (detail) {
        setSelectedTicket(detail.ticket);
        setMessages(detail.messages || []);
      }
    } catch (e) {
      console.error('Error fetching ticket detail:', e);
    }
  };

  useEffect(() => {
    loadTickets();
  }, []);

  const handleSendReply = async () => {
    if (!selectedTicketId || !replyText.trim() || sending) return;
    setSending(true);
    try {
      const res = await ApiService.sendTicketReply(currentStaff, selectedTicketId, replyText.trim());
      if (res.success && res.data) {
        setMessages(prev => [...prev, res.data!]);
        setReplyText('');
        // Refresh ticket status
        const updated = await ApiService.fetchTicketDetail(currentStaff, selectedTicketId);
        if (updated) {
          setSelectedTicket(updated.ticket);
          setTickets(prev => prev.map(t => t.id === selectedTicketId ? updated.ticket : t));
        }
      } else {
        alert('Lỗi: ' + res.message);
      }
    } catch (e: any) {
      alert('Không thể gửi tin nhắn: ' + e.message);
    } finally {
      setSending(false);
    }
  };

  const handleResolveTicket = async () => {
    if (!selectedTicketId) return;
    const notes = resolutionNote.trim() || 'Cán bộ hỗ trợ đã kiểm tra và giải quyết yêu cầu.';
    if (!confirm('Xác nhận hoàn tất và giải quyết khiếu nại/hỗ trợ này?')) return;

    try {
      const res = await ApiService.resolveSupportTicket(currentStaff, selectedTicketId, notes);
      if (res.success) {
        alert('✅ ' + res.message);
        setResolutionNote('');
        selectTicket(selectedTicketId);
        loadTickets();
      } else {
        alert('Lỗi: ' + res.message);
      }
    } catch (e: any) {
      alert('Lỗi: ' + e.message);
    }
  };

  const filteredTickets = tickets.filter(t => {
    const matchStatus = statusFilter === 'ALL' || t.status === statusFilter;
    const matchSearch = searchTerm === '' ||
      t.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.userId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.subject.toLowerCase().includes(searchTerm.toLowerCase());
    return matchStatus && matchSearch;
  });

  const openCount = tickets.filter(t => t.status === 'OPEN').length;
  const inProgressCount = tickets.filter(t => t.status === 'IN_PROGRESS').length;
  const resolvedCount = tickets.filter(t => t.status === 'RESOLVED' || t.status === 'CLOSED').length;

  const handleExportSupportCsv = () => {
    if (tickets.length === 0) {
      alert('Không có dữ liệu hỗ trợ để xuất CSV');
      return;
    }
    const bom = '\ufeff';
    const header = 'STT,Mã Ticket,Mã Khách Hàng,Tiêu Đề,Danh Mục,Mức Độ Ưu Tiên,Trạng Thái,Thời Gian Tạo\n';
    const rows = tickets.map((t, idx) =>
      `${idx + 1},"${t.id}","${t.userId}","${(t.subject || '').replace(/"/g, '""')}","${t.category}","${t.priority}","${t.status}","${t.createdAt || ''}"`
    ).join('\n');
    const blob = new Blob([bom + header + rows], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `nhat_ky_cskh_${new Date().toISOString().split('T')[0]}.csv`;
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
            <Headphones size={20} color="var(--primary-blue)" />
            TỔNG ĐÀI HỖ TRỢ KHÁCH HÀNG &amp; XỬ LÝ KHIẾU NẠI (SUPPORT DESK)
          </h2>
          <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
            Tiếp nhận, tư vấn trực tuyến và giải quyết tra soát khiếu nại giao dịch cho khách hàng
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button
            type="button"
            onClick={handleExportSupportCsv}
            disabled={loading || tickets.length === 0}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 16px',
              background: 'var(--bg-card)',
              border: '1px solid var(--border-color)',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: 600,
              color: 'var(--primary-blue)',
            }}
          >
            <Download size={14} />
            Xuất Nhật Ký CSKH (CSV)
          </button>
          <button
            type="button"
            onClick={() => {
              loadTickets();
              if (onRefresh) onRefresh();
            }}
            disabled={loading}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 16px',
              background: 'var(--bg-card)',
              border: '1px solid var(--border-color)',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: 600,
              color: 'var(--text-main)',
            }}
          >
            <RefreshCw size={14} className={loading ? 'spin' : ''} />
            Làm mới
          </button>
        </div>
      </div>

      {/* KPI Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '14px', marginBottom: '20px' }}>
        <div style={{ padding: '14px 18px', borderRadius: '10px', background: 'var(--bg-subtle)', border: '1px solid var(--border-color)' }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Tổng Yêu Cầu Gửi Đến</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: 'var(--primary-blue)', marginTop: '4px' }}>{tickets.length}</div>
        </div>
        <div style={{ padding: '14px 18px', borderRadius: '10px', background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
          <div style={{ fontSize: '12px', color: '#ef4444', fontWeight: 600 }}>Chờ Tiếp Nhận (Mới)</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#ef4444', marginTop: '4px' }}>{openCount}</div>
        </div>
        <div style={{ padding: '14px 18px', borderRadius: '10px', background: 'rgba(245, 158, 11, 0.08)', border: '1px solid rgba(245, 158, 11, 0.2)' }}>
          <div style={{ fontSize: '12px', color: '#f59e0b', fontWeight: 600 }}>Đang Xử Lý / Tra Soát</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#f59e0b', marginTop: '4px' }}>{inProgressCount}</div>
        </div>
        <div style={{ padding: '14px 18px', borderRadius: '10px', background: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
          <div style={{ fontSize: '12px', color: '#10b981', fontWeight: 600 }}>Đã Giải Quyết Xong</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#10b981', marginTop: '4px' }}>{resolvedCount}</div>
        </div>
      </div>

      {/* Filter and Search */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '18px', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: '1', minWidth: '260px' }}>
          <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input
            type="text"
            placeholder="Tìm theo Mã vé, User ID hoặc Nội dung khiếu nại..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '9px 12px 9px 36px',
              borderRadius: '8px',
              border: '1px solid var(--border-color)',
              background: 'var(--bg-input)',
              color: 'var(--text-main)',
              fontSize: '13px',
            }}
          />
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          {(['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'] as const).map(status => (
            <button
              key={status}
              type="button"
              onClick={() => setStatusFilter(status)}
              style={{
                padding: '8px 14px',
                borderRadius: '8px',
                border: '1px solid',
                borderColor: statusFilter === status ? 'var(--primary-blue)' : 'var(--border-color)',
                background: statusFilter === status ? 'var(--primary-blue)' : 'transparent',
                color: statusFilter === status ? '#ffffff' : 'var(--text-main)',
                fontSize: '12px',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              {status === 'ALL' && 'Tất cả'}
              {status === 'OPEN' && 'Chờ tiếp nhận'}
              {status === 'IN_PROGRESS' && 'Đang giải quyết'}
              {status === 'RESOLVED' && 'Đã xử lý'}
              {status === 'CLOSED' && 'Đã đóng'}
            </button>
          ))}
        </div>
      </div>

      {/* Split View */}
      <div style={{ display: 'grid', gridTemplateColumns: '400px 1fr', gap: '18px', minHeight: '520px' }}>
        {/* Left: Ticket List */}
        <div style={{ border: '1px solid var(--border-color)', borderRadius: '10px', overflowY: 'auto', maxHeight: '600px', background: 'var(--bg-subtle)' }}>
          {filteredTickets.length === 0 ? (
            <div style={{ padding: '36px', textAlign: 'center', color: 'var(--text-muted)', fontSize: '13px' }}>
              Không tìm thấy yêu cầu hỗ trợ nào phù hợp
            </div>
          ) : (
            filteredTickets.map(t => {
              const isSelected = selectedTicketId === t.id;
              return (
                <div
                  key={t.id}
                  onClick={() => selectTicket(t.id)}
                  style={{
                    padding: '14px 16px',
                    borderBottom: '1px solid var(--border-color)',
                    cursor: 'pointer',
                    background: isSelected ? 'rgba(37, 99, 235, 0.08)' : 'transparent',
                    borderLeft: isSelected ? '4px solid var(--primary-blue)' : '4px solid transparent',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                    <span style={{
                      fontSize: '10.5px',
                      fontWeight: 700,
                      padding: '2px 8px',
                      borderRadius: '4px',
                      background: t.status === 'OPEN' ? 'rgba(239, 68, 68, 0.15)' :
                                  t.status === 'IN_PROGRESS' ? 'rgba(245, 158, 11, 0.15)' :
                                  'rgba(16, 185, 129, 0.15)',
                      color: t.status === 'OPEN' ? '#ef4444' :
                             t.status === 'IN_PROGRESS' ? '#f59e0b' : '#10b981',
                    }}>
                      {t.status === 'OPEN' ? 'CHỜ XỬ LÝ' : t.status === 'IN_PROGRESS' ? 'ĐANG TRA SOÁT' : 'ĐÃ GIẢI QUYẾT'}
                    </span>
                    <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      {new Date(t.createdAt).toLocaleDateString('vi-VN')} {new Date(t.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <div style={{ fontWeight: 700, fontSize: '13px', color: 'var(--text-main)', marginBottom: '4px' }}>
                    {t.subject}
                  </div>
                  <div style={{ fontSize: '11.5px', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between' }}>
                    <span>Khách: <b className="mono">{t.userId.substring(0, 10)}...</b></span>
                    <span style={{ fontWeight: 600, color: 'var(--primary-blue)' }}>{t.category}</span>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Right: Ticket Conversation & Resolution */}
        <div style={{ border: '1px solid var(--border-color)', borderRadius: '10px', display: 'flex', flexDirection: 'column', background: 'var(--bg-card)' }}>
          {selectedTicket ? (
            <>
              {/* Ticket Top bar */}
              <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', background: 'var(--bg-subtle)', borderRadius: '10px 10px 0 0' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <h3 style={{ fontSize: '15px', fontWeight: 800, color: 'var(--text-main)', marginBottom: '4px' }}>
                      {selectedTicket.subject}
                    </h3>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'flex', gap: '16px' }}>
                      <span>Mã ticket: <b className="mono">{selectedTicket.id}</b></span>
                      <span>User ID: <b className="mono">{selectedTicket.userId}</b></span>
                      <span>Ưu tiên: <b>{selectedTicket.priority}</b></span>
                    </div>
                  </div>
                  {selectedTicket.status !== 'RESOLVED' && selectedTicket.status !== 'CLOSED' && (
                    <button
                      type="button"
                      onClick={handleResolveTicket}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '8px 16px',
                        background: '#10b981',
                        color: '#ffffff',
                        border: 'none',
                        borderRadius: '8px',
                        fontWeight: 700,
                        fontSize: '12px',
                        cursor: 'pointer',
                      }}
                    >
                      <CheckCircle2 size={15} />
                      Hoàn Tất &amp; Đóng Ticket
                    </button>
                  )}
                </div>
              </div>

              {/* Message Thread */}
              <div style={{ flex: 1, padding: '20px', overflowY: 'auto', maxHeight: '380px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {messages.length === 0 ? (
                  <div style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '24px', fontSize: '13px' }}>
                    Chưa có tin nhắn nào trong luồng hỗ trợ này.
                  </div>
                ) : (
                  messages.map(m => {
                    const isStaff = m.senderType === 'STAFF';
                    return (
                      <div
                        key={m.id}
                        style={{
                          alignSelf: isStaff ? 'flex-end' : 'flex-start',
                          maxWidth: '75%',
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: isStaff ? 'flex-end' : 'flex-start',
                        }}
                      >
                        <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginBottom: '3px' }}>
                          {isStaff ? 'Cán bộ ngân hàng' : 'Khách hàng'} • {new Date(m.sentAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}
                        </div>
                        <div
                          style={{
                            padding: '10px 14px',
                            borderRadius: isStaff ? '14px 14px 2px 14px' : '14px 14px 14px 2px',
                            background: isStaff ? 'var(--primary-blue)' : 'var(--bg-subtle)',
                            color: isStaff ? '#ffffff' : 'var(--text-main)',
                            border: isStaff ? 'none' : '1px solid var(--border-color)',
                            fontSize: '13px',
                            lineHeight: 1.45,
                            wordBreak: 'break-word',
                          }}
                        >
                          {m.content}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Reply Input Bar */}
              {selectedTicket.status !== 'CLOSED' ? (
                <div style={{ padding: '14px 20px', borderTop: '1px solid var(--border-color)', background: 'var(--bg-subtle)', borderRadius: '0 0 10px 10px' }}>
                  <div style={{ display: 'flex', gap: '10px' }}>
                    <input
                      type="text"
                      placeholder="Nhập nội dung phản hồi, tư vấn hoặc kết quả tra soát cho khách hàng..."
                      value={replyText}
                      onChange={e => setReplyText(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter') handleSendReply();
                      }}
                      disabled={sending}
                      style={{
                        flex: 1,
                        padding: '10px 14px',
                        borderRadius: '8px',
                        border: '1px solid var(--border-color)',
                        background: 'var(--bg-input)',
                        color: 'var(--text-main)',
                        fontSize: '13px',
                      }}
                    />
                    <button
                      type="button"
                      onClick={handleSendReply}
                      disabled={sending || !replyText.trim()}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '10px 18px',
                        background: 'var(--primary-blue)',
                        color: '#ffffff',
                        border: 'none',
                        borderRadius: '8px',
                        fontWeight: 700,
                        fontSize: '13px',
                        cursor: sending || !replyText.trim() ? 'not-allowed' : 'pointer',
                        opacity: sending || !replyText.trim() ? 0.6 : 1,
                      }}
                    >
                      <Send size={15} />
                      Gửi phản hồi
                    </button>
                  </div>
                </div>
              ) : (
                <div style={{ padding: '14px 20px', borderTop: '1px solid var(--border-color)', textAlign: 'center', color: 'var(--text-muted)', fontSize: '13px' }}>
                  Ticket này đã được đóng hoàn tất. Không thể gửi thêm tin nhắn.
                </div>
              )}
            </>
          ) : (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontSize: '14px' }}>
              Chọn một yêu cầu hỗ trợ ở danh sách bên trái để xem chi tiết và phản hồi
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

