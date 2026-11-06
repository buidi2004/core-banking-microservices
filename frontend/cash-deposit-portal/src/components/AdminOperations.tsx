import React, { useCallback, useEffect, useState } from 'react';
import { LoggedInStaff } from '../types';

type PanelState<T> = { status: 'idle' | 'loading' | 'ready' | 'error'; data?: T; message?: string };

interface AdminOperationsProps {
  staff: LoggedInStaff | null;
}

interface TransactionPage {
  content?: Array<Record<string, unknown>>;
  totalElements?: number;
}

type ScheduledTransferPage = Array<Record<string, unknown>>;

interface ApiEnvelope<T> {
  data?: T;
}

function headers(staff: LoggedInStaff): HeadersInit {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${staff.token}`,
    'X-User-Id': staff.id,
    'X-User-Role': staff.role === 'MANAGER' ? 'ROLE_MANAGER' : 'ROLE_TELLER',
    'X-User-Roles': staff.role === 'MANAGER' ? 'ROLE_MANAGER' : 'ROLE_TELLER',
    'X-Branch-Id': staff.branchId,
  };

}

async function getJson<T>(path: string, staff: LoggedInStaff): Promise<T> {
  const response = await fetch(path, { headers: headers(staff) });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  const body = await response.json() as ApiEnvelope<T> & T;
  return (body.data ?? body) as T;
}

async function postJson<T>(path: string, staff: LoggedInStaff): Promise<T> {
  const response = await fetch(path, { method: 'POST', headers: headers(staff) });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  const body = await response.json() as ApiEnvelope<T> & T;
  return (body.data ?? body) as T;
}

export function AdminOperations({ staff }: AdminOperationsProps) {
  const [transactions, setTransactions] = useState<PanelState<TransactionPage>>({ status: 'idle' });
  const [scheduled, setScheduled] = useState<PanelState<ScheduledTransferPage>>({ status: 'idle' });
  const [aml, setAml] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [reconciliation, setReconciliation] = useState<PanelState<Record<string, unknown>>>({ status: 'idle' });
  const [eod, setEod] = useState<PanelState<Record<string, unknown>>>({ status: 'idle' });
  const [vaultTransfers, setVaultTransfers] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [staffDirectory, setStaffDirectory] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [supportTickets, setSupportTickets] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [transactionQuery, setTransactionQuery] = useState('');
  const [amlThreshold, setAmlThreshold] = useState('400000000');
  const [operationMessage, setOperationMessage] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  const refresh = useCallback(async () => {
    if (!staff?.token) return;
    setTransactions({ status: 'loading' });
    setScheduled({ status: 'loading' });
    setAml({ status: 'loading' });
    setReconciliation({ status: 'loading' });
    setVaultTransfers({ status: 'loading' });
    setStaffDirectory({ status: 'loading' });
    setSupportTickets({ status: 'loading' });

    const query = new URLSearchParams({ page: '0', size: '20' });
    if (transactionQuery.trim()) query.set('walletId', transactionQuery.trim());
    const amlParams = new URLSearchParams({ minAmount: amlThreshold, page: '0', size: '20' });
    const [transactionResult, scheduledResult, amlResult, reconciliationResult, vaultResult, staffResult, supportResult] = await Promise.allSettled([
      getJson<TransactionPage>(`/api/v1/transactions?${query}`, staff),
      getJson<ScheduledTransferPage>('/api/v1/payments/scheduled-transfers', staff),
      getJson<{ content?: unknown[]; totalElements?: number }>(`/api/v1/transactions/aml/large?${amlParams}`, staff),
      getJson<Record<string, unknown>>('/api/v1/ledger/accounts/balance-check', staff),
      getJson<unknown[]>('/api/v1/cash/vault/transfers', staff),
      getJson<unknown[]>(`/api/v1/staff/branch/${encodeURIComponent(staff.branchId)}`, staff),
      getJson<unknown[]>('/api/v1/support/admin/tickets', staff),
    ]);

    setTransactions(transactionResult.status === 'fulfilled'
      ? { status: 'ready', data: transactionResult.value }
      : { status: 'error', message: transactionResult.reason instanceof Error ? transactionResult.reason.message : 'Không tải được giao dịch' });
    setScheduled(scheduledResult.status === 'fulfilled'
      ? { status: 'ready', data: scheduledResult.value }
      : { status: 'error', message: scheduledResult.reason instanceof Error ? scheduledResult.reason.message : 'Không tải được lệnh định kỳ' });
    setAml(amlResult.status === 'fulfilled'
      ? { status: 'ready', data: amlResult.value.content ?? [] }
      : { status: 'error', message: amlResult.reason instanceof Error ? amlResult.reason.message : 'Không tải được cảnh báo AML' });
    setReconciliation(reconciliationResult.status === 'fulfilled'
      ? { status: 'ready', data: reconciliationResult.value }
      : { status: 'error', message: reconciliationResult.reason instanceof Error ? reconciliationResult.reason.message : 'Không tải được đối soát' });
    setVaultTransfers(vaultResult.status === 'fulfilled'
      ? { status: 'ready', data: vaultResult.value }
      : { status: 'error', message: vaultResult.reason instanceof Error ? vaultResult.reason.message : 'Không tải được lệnh điều chuyển két' });
    setStaffDirectory(staffResult.status === 'fulfilled'
      ? { status: 'ready', data: staffResult.value }
      : { status: 'error', message: staffResult.reason instanceof Error ? staffResult.reason.message : 'Không tải được danh sách cán bộ' });
    setSupportTickets(supportResult.status === 'fulfilled'
      ? { status: 'ready', data: supportResult.value }
      : { status: 'error', message: supportResult.reason instanceof Error ? supportResult.reason.message : 'Không tải được ticket hỗ trợ' });
    setLastRefresh(new Date());
  }, [amlThreshold, staff, transactionQuery]);

  useEffect(() => { void refresh(); }, [refresh]);

  const executeDueTransfers = async () => {
    if (!staff?.token) return;
    setOperationMessage(null);
    try {
      await postJson<unknown>('/api/v1/payments/scheduled-transfers/execute-due', staff);
      setOperationMessage('Đã gửi yêu cầu chạy các lệnh đến hạn.');
      await refresh();
    } catch (error) {
      setOperationMessage(`Không thể chạy lệnh đến hạn: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
    }
  };

  const closeEndOfDay = async () => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setEod({ status: 'loading' });
    try {
      const result = await postJson<Record<string, unknown>>('/api/v1/ledger/admin/eod/close-day', staff);
      setEod({ status: 'ready', data: result });
    } catch (error) {
      setEod({ status: 'error', message: error instanceof Error ? error.message : 'Không thể khóa sổ cuối ngày' });
    }
  };

  const card = (title: string, state: PanelState<unknown>, detail: React.ReactNode) => (
    <section className="card" style={{ minHeight: 150 }}>
      <div className="card-header">
        <h3>{title}</h3>
        <span className={`badge ${state.status === 'ready' ? 'badge-green' : state.status === 'error' ? 'badge-red' : 'badge-cyan'}`}>
          {state.status === 'ready' ? 'LIVE' : state.status === 'loading' ? 'ĐANG TẢI' : state.status === 'error' ? 'LỖI' : 'CHƯA TẢI'}
        </span>
      </div>
      {state.status === 'error' ? <p className="text-muted">Không có dữ liệu: {state.message}</p> : detail}
    </section>
  );

  if (!staff) return <section className="card"><p>Đăng nhập để truy cập trung tâm vận hành.</p></section>;

  const transactionCount = transactions.data?.totalElements ?? transactions.data?.content?.length ?? 0;
  const scheduledCount = scheduled.data?.length ?? 0;
  const amlCount = aml.data?.length ?? 0;
  const pendingVaultTransfers = (vaultTransfers.data ?? []).filter((item) => {
    if (!item || typeof item !== 'object') return false;
    const status = (item as { status?: unknown }).status;
    return typeof status === 'string'
      && ['PENDING', 'PENDING_APPROVAL'].includes(status.toUpperCase());
  });

  const approveVaultTransfer = async (id: string) => {
    if (staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      await postJson<unknown>(`/api/v1/cash/vault/transfers/${encodeURIComponent(id)}/approve`, staff);
      setOperationMessage('Đã phê duyệt lệnh điều chuyển két quỹ.');
      await refresh();
    } catch (error) {
      setOperationMessage(`Không thể phê duyệt lệnh điều chuyển: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
    }
  };

  const updateSupportTicket = async (id: string, action: 'resolve' | 'close') => {
    if (staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      const suffix = action === 'resolve'
        ? `?resolutionNotes=${encodeURIComponent('Đã xử lý bởi Trung tâm vận hành')}`
        : '';
      await postJson<unknown>(`/api/v1/support/tickets/${encodeURIComponent(id)}/${action}${suffix}`, staff);
      setOperationMessage(action === 'resolve' ? 'Đã đánh dấu ticket đã giải quyết.' : 'Đã đóng ticket.');
      await refresh();
    } catch (error) {
      setOperationMessage(`Không thể cập nhật ticket: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
    }
  };

  return (
    <div className="stack gap-lg">
      <div className="section-heading">
        <div>
          <h2>Trung tâm vận hành</h2>
          <p className="text-muted">Dữ liệu thật theo quyền {staff.role} · Chi nhánh {staff.branchName || staff.branchId}</p>
        </div>
        <button className="button button-secondary" onClick={() => void refresh()}>Làm mới</button>
      </div>
      {lastRefresh && <p className="text-muted">Cập nhật lúc {lastRefresh.toLocaleTimeString('vi-VN')}</p>}
      <div className="card">
        <div className="grid grid-3">
          <label>
            Wallet ID
            <input value={transactionQuery} onChange={(event) => setTransactionQuery(event.target.value)} placeholder="Nhập wallet ID để tra cứu" />
          </label>
          <label>
            Ngưỡng AML (VND)
            <input inputMode="numeric" value={amlThreshold} onChange={(event) => setAmlThreshold(event.target.value)} />
          </label>
          <div style={{ alignSelf: 'end' }}>
            <button className="button button-secondary" onClick={() => void refresh()}>Áp dụng bộ lọc</button>
          </div>
        </div>
      </div>
      {operationMessage && <div className="notice">{operationMessage}</div>}
      <div className="grid grid-3">
        {card('Tra cứu giao dịch', transactions, <strong>{transactionCount} giao dịch trong trang hiện tại</strong>)}
        {card('Cảnh báo AML/PCRT', aml, <strong>{amlCount} giao dịch giá trị lớn cần rà soát</strong>)}
        {card('Lệnh chuyển định kỳ', scheduled, <strong>{scheduledCount} lệnh đang được theo dõi</strong>)}
      </div>
      <div className="grid grid-2">
        {card('Điều hành lệnh đến hạn', scheduled, (
          <div>
            <p className="text-muted">Chỉ kích hoạt job backend, không tạo giao dịch trực tiếp trên trình duyệt.</p>
            <button className="button button-secondary" onClick={() => void executeDueTransfers()}>Chạy lệnh đến hạn</button>
          </div>
        ))}
        {card('Đối soát & EOD', reconciliation, (
          <div>
            <p className="text-muted">Đối soát hiện tại: {String(reconciliation.data?.balanced ?? 'chưa có dữ liệu')}</p>
            {staff.role === 'MANAGER' && (
              <button className="button button-secondary" onClick={() => void closeEndOfDay()}>
                Khóa sổ cuối ngày
              </button>
            )}
            {eod.status === 'ready' && <p className="text-muted">Đã nhận chứng chỉ EOD từ ledger.</p>}
            {eod.status === 'error' && <p className="text-muted">EOD lỗi: {eod.message}</p>}
          </div>
        ))}
        {card('Case vận hành & audit log', { status: 'idle' }, <p className="text-muted">Cần endpoint case lifecycle và audit trail tập trung trước khi bật thao tác quản trị.</p>)}
        {card('Điều chuyển két quỹ', vaultTransfers, (
          <div>
            <strong>{vaultTransfers.data?.length ?? 0} lệnh trong chi nhánh</strong>
            {pendingVaultTransfers.length > 0 && (
              <div className="stack gap-sm" style={{ marginTop: 12 }}>
                <p className="text-muted">{pendingVaultTransfers.length} lệnh đang chờ duyệt.</p>
                {staff.role === 'MANAGER' && pendingVaultTransfers.map((item) => {
                  const record = item as { id?: unknown; orderCode?: unknown };
                  const id = typeof record.id === 'string' ? record.id : '';
                  if (!id) return null;
                  return (
                    <button
                      className="button button-secondary"
                      key={id}
                      onClick={() => void approveVaultTransfer(id)}
                    >
                      Duyệt {typeof record.orderCode === 'string' ? record.orderCode : id}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        ))}
        {card('Nhân sự chi nhánh', staffDirectory, <strong>{staffDirectory.data?.length ?? 0} cán bộ được phân quyền</strong>)}
        {card('Ticket hỗ trợ', supportTickets, (
          <div>
            <strong>{supportTickets.data?.length ?? 0} ticket toàn hệ thống</strong>
            {staff.role === 'MANAGER' && supportTickets.data && supportTickets.data.slice(0, 5).map((item) => {
              const record = item as { id?: unknown; status?: unknown; subject?: unknown };
              const id = typeof record.id === 'string' ? record.id : '';
              if (!id) return null;
              const status = typeof record.status === 'string' ? record.status.toUpperCase() : '';
              return (
                <div className="stack gap-sm" style={{ marginTop: 10 }} key={id}>
                  <span>{typeof record.subject === 'string' ? record.subject : id} · {status || 'OPEN'}</span>
                  {status !== 'CLOSED' && (
                    <div className="inline-actions">
                      {status !== 'RESOLVED' && (
                        <button className="button button-secondary" onClick={() => void updateSupportTicket(id, 'resolve')}>Giải quyết</button>
                      )}
                      <button className="button button-secondary" onClick={() => void updateSupportTicket(id, 'close')}>Đóng</button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}
