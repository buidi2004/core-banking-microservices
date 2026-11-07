import React, { useCallback, useEffect, useState } from 'react';
import { LoggedInStaff, DisputeCase, NotificationDlqStats, NotificationProviderHealth, StaffMember, ResilienceDashboardData } from '../types';
import { ApiService } from '../api';

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
  const [eodReadiness, setEodReadiness] = useState<PanelState<any>>({ status: 'idle' });
  const [vaultTransfers, setVaultTransfers] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [staffDirectory, setStaffDirectory] = useState<PanelState<StaffMember[]>>({ status: 'idle' });
  const [showCreateStaff, setShowCreateStaff] = useState(false);
  const [newStaffUsername, setNewStaffUsername] = useState('');
  const [newStaffFullName, setNewStaffFullName] = useState('');
  const [newStaffPhone, setNewStaffPhone] = useState('');
  const [newStaffEmail, setNewStaffEmail] = useState('');
  const [newStaffRole, setNewStaffRole] = useState('TELLER');
  const [newStaffBranch, setNewStaffBranch] = useState(staff?.branchId || 'BR_Q1');
  const [newStaffPassword, setNewStaffPassword] = useState('Staff@123456');
  const [supportTickets, setSupportTickets] = useState<PanelState<unknown[]>>({ status: 'idle' });
  const [disputes, setDisputes] = useState<PanelState<DisputeCase[]>>({ status: 'idle' });
  const [notificationDlq, setNotificationDlq] = useState<PanelState<NotificationDlqStats>>({ status: 'idle' });
  const [notificationHealth, setNotificationHealth] = useState<PanelState<NotificationProviderHealth>>({ status: 'idle' });
  const [testPushRecipient, setTestPushRecipient] = useState('');
  const [testPushTitle, setTestPushTitle] = useState('Thông báo kiểm thử');
  const [testPushMessage, setTestPushMessage] = useState('');
  const [transactionQuery, setTransactionQuery] = useState('');
  const [amlThreshold, setAmlThreshold] = useState('400000000');
  const [operationMessage, setOperationMessage] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);
  const [manualRevTxId, setManualRevTxId] = useState('');
  const [manualRevReason, setManualRevReason] = useState('');
  const [resilience, setResilience] = useState<PanelState<ResilienceDashboardData>>({ status: 'idle' });
  const [exportingReport, setExportingReport] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!staff?.token) return;
    setTransactions({ status: 'loading' });
    setScheduled({ status: 'loading' });
    setAml({ status: 'loading' });
    setReconciliation({ status: 'loading' });
    setVaultTransfers({ status: 'loading' });
    setStaffDirectory({ status: 'loading' });
    setSupportTickets({ status: 'loading' });
    setDisputes({ status: 'loading' });
    setNotificationDlq({ status: 'loading' });
    setNotificationHealth({ status: 'loading' });
    setEodReadiness({ status: 'loading' });
    setResilience({ status: 'loading' });

    const query = new URLSearchParams({ page: '0', size: '20' });
    if (transactionQuery.trim()) query.set('walletId', transactionQuery.trim());
    const amlParams = new URLSearchParams({ minAmount: amlThreshold, page: '0', size: '20' });
    const [transactionResult, scheduledResult, amlResult, reconciliationResult, vaultResult, staffResult, supportResult, disputeResult, dlqResult, healthResult, eodReadinessResult, resilienceResult] = await Promise.allSettled([
      getJson<TransactionPage>(`/api/v1/transactions?${query}`, staff),
      getJson<ScheduledTransferPage>('/api/v1/payments/scheduled-transfers', staff),
      getJson<{ content?: unknown[]; totalElements?: number }>(`/api/v1/transactions/aml/large?${amlParams}`, staff),
      getJson<Record<string, unknown>>('/api/v1/ledger/accounts/balance-check', staff),
      getJson<unknown[]>('/api/v1/cash/vault/transfers', staff),
      ApiService.fetchStaffMembers(staff),
      getJson<unknown[]>('/api/v1/support/admin/tickets', staff),
      getJson<{ content?: DisputeCase[]; totalElements?: number }>('/api/v1/payments/disputes', staff),
      ApiService.fetchNotificationDlqStats(staff),
      ApiService.fetchNotificationProviderHealth(staff),
      ApiService.fetchEodReadiness(staff),
      ApiService.fetchResilienceDashboard(staff),
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
    setDisputes(disputeResult.status === 'fulfilled'
      ? { status: 'ready', data: disputeResult.value.content ?? [] }
      : { status: 'error', message: disputeResult.reason instanceof Error ? disputeResult.reason.message : 'Không tải được yêu cầu tra soát' });
    setNotificationDlq(dlqResult.status === 'fulfilled' && dlqResult.value
      ? { status: 'ready', data: dlqResult.value }
      : { status: 'error', message: dlqResult.status === 'rejected' && dlqResult.reason instanceof Error ? dlqResult.reason.message : 'Không tải được thống kê DLQ' });
    setNotificationHealth(healthResult.status === 'fulfilled' && healthResult.value
      ? { status: 'ready', data: healthResult.value }
      : { status: 'error', message: healthResult.status === 'rejected' && healthResult.reason instanceof Error ? healthResult.reason.message : 'Không tải được trạng thái thông báo' });
    setEodReadiness(eodReadinessResult.status === 'fulfilled' && eodReadinessResult.value
      ? { status: 'ready', data: eodReadinessResult.value }
      : { status: 'error', message: 'Không tải được trạng thái EOD' });
    setResilience(resilienceResult.status === 'fulfilled' && resilienceResult.value
      ? { status: 'ready', data: resilienceResult.value }
      : { status: 'error', message: 'Không tải được chỉ số Resilience' });
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

  const closeEndOfDay = async (force: boolean = false) => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setEod({ status: 'loading' });
    setOperationMessage(null);
    try {
      const result = await ApiService.closeEndOfDay(staff, force, 'Khóa sổ qua Portal Quản trị');
      if (result.success) {
        setEod({ status: 'ready', data: result.data });
        setOperationMessage(`Khóa sổ cuối ngày ${result.data?.valueDate} thành công (${result.data?.status}). Chuyển sang ngày ${result.data?.nextValueDate}.`);
        await refresh();
      } else {
        setEod({ status: 'error', message: result.message });
        setOperationMessage(`Lỗi khóa sổ: ${result.message}`);
      }
    } catch (error) {
      setEod({ status: 'error', message: error instanceof Error ? error.message : 'Không thể khóa sổ cuối ngày' });
    }
  };

  const handleDrainOutbox = async () => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      const res = await ApiService.drainPaymentOutbox(staff);
      if (res.success) {
        setOperationMessage(`Đã kích hoạt xả Outbox: còn lại ${res.data?.remainingPending ?? 0} sự kiện.`);
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi xả outbox');
      }
    } catch (error) {
      setOperationMessage(`Lỗi xả outbox: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
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

  const handleResolveDispute = async (id: string, action: 'REFUND' | 'REJECT') => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      const res = await ApiService.resolveDispute(
        staff,
        id,
        action,
        action === 'REFUND' ? 'Quản lý duyệt hoàn tiền qua Trung tâm vận hành' : 'Quản lý từ chối tra soát'
      );
      if (res.success) {
        setOperationMessage(action === 'REFUND' ? 'Đã duyệt hoàn tiền và đảo bút toán thành công.' : 'Đã từ chối tra soát.');
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi xử lý tra soát');
      }
    } catch (error) {
      setOperationMessage(`Lỗi xử lý tra soát: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
    }
  };

  const handleManualReversal = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!staff?.token || staff.role !== 'MANAGER') return;
    if (!manualRevTxId.trim() || !manualRevReason.trim()) {
      setOperationMessage('Vui lòng nhập đầy đủ mã giao dịch và lý do đảo bút toán.');
      return;
    }
    setOperationMessage(null);
    try {
      const res = await ApiService.executeManualReversal(staff, manualRevTxId.trim(), manualRevReason.trim());
      if (res.success) {
        setOperationMessage(`Đảo bút toán thành công cho GD #${manualRevTxId}. Tiền đã hoàn về ví nguồn.`);
        setManualRevTxId('');
        setManualRevReason('');
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi đảo bút toán');
      }
    } catch (error) {
      setOperationMessage(`Lỗi đảo bút toán: ${error instanceof Error ? error.message : 'lỗi không xác định'}`);
    }
  };

  const handleRetryDlq = async () => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      const res = await ApiService.retryNotificationDlq(staff, 50);
      if (res.success) {
        setOperationMessage(`Đã retry DLQ thành công: chuyển ${res.data?.requeued ?? 0} tin về hàng đợi chính.`);
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi retry DLQ');
      }
    } catch (e: any) {
      setOperationMessage(`Lỗi retry DLQ: ${e.message}`);
    }
  };

  const handlePurgeDlq = async () => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    if (!window.confirm('Bạn có chắc chắn muốn dọn sạch toàn bộ tin trong DLQ không?')) return;
    setOperationMessage(null);
    try {
      const res = await ApiService.purgeNotificationDlq(staff);
      if (res.success) {
        setOperationMessage('Đã dọn sạch hàng đợi Dead Letter Queue.');
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi dọn sạch DLQ');
      }
    } catch (e: any) {
      setOperationMessage(`Lỗi dọn sạch DLQ: ${e.message}`);
    }
  };

  const handleSendTestPush = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!staff?.token || staff.role !== 'MANAGER') return;
    if (!testPushRecipient.trim() || !testPushMessage.trim()) {
      setOperationMessage('Vui lòng nhập mã người nhận và nội dung thông báo kiểm thử.');
      return;
    }
    setOperationMessage(null);
    try {
      const res = await ApiService.sendTestNotification(staff, {
        recipientId: testPushRecipient.trim(),
        title: testPushTitle.trim(),
        message: testPushMessage.trim(),
        channel: 'ALL',
      });
      if (res.success) {
        setOperationMessage(`Đã gửi thông báo kiểm thử tới ${testPushRecipient}: FCM=${res.data?.fcmResult}, WebSocket=${res.data?.wsResult}`);
        setTestPushMessage('');
      } else {
        setOperationMessage(res.message || 'Lỗi gửi thông báo kiểm thử');
      }
    } catch (e: any) {
      setOperationMessage(`Lỗi gửi thông báo: ${e.message}`);
    }
  };

  const handleCreateStaff = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!staff?.token || staff.role !== 'MANAGER') return;
    if (!newStaffUsername.trim() || !newStaffFullName.trim() || !newStaffPhone.trim() || !newStaffEmail.trim()) {
      setOperationMessage('Vui lòng điền đầy đủ thông tin cán bộ.');
      return;
    }
    setOperationMessage(null);
    try {
      const res = await ApiService.createStaffMember(staff, {
        username: newStaffUsername.trim(),
        fullName: newStaffFullName.trim(),
        phoneNumber: newStaffPhone.trim(),
        email: newStaffEmail.trim(),
        role: newStaffRole,
        branchId: newStaffBranch.trim(),
        initialPassword: newStaffPassword.trim(),
      });
      if (res.success) {
        setOperationMessage(`Tạo cán bộ ${res.data?.username} (${res.data?.role}) thành công.`);
        setShowCreateStaff(false);
        setNewStaffUsername('');
        setNewStaffFullName('');
        setNewStaffPhone('');
        setNewStaffEmail('');
        await refresh();
      } else {
        setOperationMessage(res.message || 'Lỗi tạo mới cán bộ');
      }
    } catch (error: any) {
      setOperationMessage(`Lỗi tạo cán bộ: ${error.message}`);
    }
  };

  const handleToggleLockStaff = async (targetStaff: StaffMember) => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    setOperationMessage(null);
    try {
      if (targetStaff.status === 'ACTIVE') {
        const reason = window.prompt(`Nhập lý do khóa tài khoản cán bộ ${targetStaff.username}:`, 'Khóa bởi Quản lý chi nhánh');
        if (!reason) return;
        const res = await ApiService.lockStaffMember(staff, targetStaff.id, reason);
        if (res.success) {
          setOperationMessage(`Đã khóa tài khoản cán bộ ${targetStaff.username}.`);
          await refresh();
        } else {
          setOperationMessage(res.message || 'Lỗi khóa tài khoản cán bộ');
        }
      } else {
        const res = await ApiService.unlockStaffMember(staff, targetStaff.id);
        if (res.success) {
          setOperationMessage(`Đã mở khóa tài khoản cán bộ ${targetStaff.username}.`);
          await refresh();
        } else {
          setOperationMessage(res.message || 'Lỗi mở khóa cán bộ');
        }
      }
    } catch (error: any) {
      setOperationMessage(`Lỗi xử lý tài khoản: ${error.message}`);
    }
  };

  const handleResetStaffPassword = async (targetStaff: StaffMember) => {
    if (!staff?.token || staff.role !== 'MANAGER') return;
    const newPass = window.prompt(`Nhập mật khẩu mới cho cán bộ ${targetStaff.username}:`, 'Staff@123456');
    if (!newPass) return;
    setOperationMessage(null);
    try {
      const res = await ApiService.resetStaffPassword(staff, targetStaff.id, newPass);
      if (res.success) {
        setOperationMessage(`Đặt lại mật khẩu thành công cho cán bộ ${targetStaff.username}.`);
      } else {
        setOperationMessage(res.message || 'Lỗi đặt lại mật khẩu');
      }
    } catch (error: any) {
      setOperationMessage(`Lỗi đặt lại mật khẩu: ${error.message}`);
    }
  };

  const handleDownloadReport = async (endpointUrl: string, filename: string, reportName: string) => {
    if (!staff?.token) return;
    setExportingReport(reportName);
    setOperationMessage(null);
    try {
      const res = await ApiService.downloadExportFile(staff, endpointUrl, filename);
      if (res.success) {
        setOperationMessage(`Đã xuất và tải xuống thành công báo cáo "${reportName}".`);
      } else {
        setOperationMessage(res.message || `Lỗi tải báo cáo "${reportName}"`);
      }
    } catch (e: any) {
      setOperationMessage(`Lỗi xuất báo cáo: ${e.message}`);
    } finally {
      setExportingReport(null);
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
        {card('Khóa sổ cuối ngày (EOD / COB Gates)', reconciliation, (
          <div className="stack gap-sm">
            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', fontSize: '11px' }}>
              <span className={`badge ${reconciliation.data?.balanced ? 'badge-green' : 'badge-red'}`}>
                Cân đối kép: {reconciliation.data?.balanced ? 'KHỚP' : 'LỆCH'}
              </span>
              <span className={`badge ${eodReadiness.data?.accountChecksumValid ? 'badge-green' : 'badge-red'}`}>
                Checksum TK: {eodReadiness.data?.accountChecksumValid ? 'KHỚP' : 'LỆCH'}
              </span>
              <span className={`badge ${eodReadiness.data?.makerCheckerPending === 0 ? 'badge-green' : 'badge-amber'}`}>
                Duyệt MC: {eodReadiness.data?.makerCheckerPending ?? 0} chờ
              </span>
              <span className={`badge ${eodReadiness.data?.outboxPending === 0 ? 'badge-green' : 'badge-amber'}`}>
                Outbox: {eodReadiness.data?.outboxPending ?? 0} tồn
              </span>
            </div>
            {eodReadiness.data?.blockingReasons && eodReadiness.data.blockingReasons.length > 0 && (
              <div style={{ fontSize: '11px', color: '#f59e0b', background: 'rgba(245, 158, 11, 0.1)', padding: '6px', borderRadius: '4px' }}>
                <div style={{ fontWeight: 600 }}>Cảnh báo cổng kiểm soát:</div>
                <ul style={{ margin: 0, paddingLeft: '16px' }}>
                  {eodReadiness.data.blockingReasons.slice(0, 3).map((r: string, idx: number) => (
                    <li key={idx}>{r}</li>
                  ))}
                </ul>
              </div>
            )}
            {staff.role === 'MANAGER' && (
              <div className="inline-actions" style={{ marginTop: 4 }}>
                {eodReadiness.data?.outboxPending > 0 && (
                  <button className="button button-secondary" style={{ fontSize: '11px', padding: '3px 8px' }} onClick={() => void handleDrainOutbox()}>
                    Xả Outbox
                  </button>
                )}
                <button
                  className="button button-secondary"
                  style={{ fontSize: '11px', padding: '3px 8px' }}
                  onClick={() => void closeEndOfDay(false)}
                  disabled={Boolean(eodReadiness.data && !eodReadiness.data.readyToClose)}
                >
                  Khóa sổ cuối ngày
                </button>
                {eodReadiness.data && !eodReadiness.data.readyToClose && reconciliation.data?.balanced && (
                  <button
                    className="button button-secondary"
                    style={{ fontSize: '11px', padding: '3px 8px', color: '#f59e0b' }}
                    onClick={() => void closeEndOfDay(true)}
                  >
                    Khóa sổ cưỡng chế (Force)
                  </button>
                )}
              </div>
            )}
            {eod.status === 'ready' && <p className="text-muted" style={{ fontSize: '11px' }}>Khóa sổ gần nhất: #{String(eod.data?.eodBatchId)} ({String(eod.data?.status)})</p>}
            {eod.status === 'error' && <p className="text-muted" style={{ fontSize: '11px', color: '#ef4444' }}>Lỗi: {eod.message}</p>}
          </div>
        ))}
        {card('Tra soát & Đảo bút toán / Hoàn tiền', disputes, (
          <div className="stack gap-sm">
            <strong>{disputes.data?.length ?? 0} yêu cầu tra soát</strong>
            {disputes.data && disputes.data.length > 0 && (
              <div className="stack gap-xs" style={{ maxHeight: 200, overflowY: 'auto' }}>
                {disputes.data.slice(0, 5).map((d) => (
                  <div key={d.id} style={{ padding: '8px', border: '1px solid var(--border-color)', borderRadius: '6px', fontSize: '12px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 600 }}>
                      <span>GD #{d.transactionId?.substring(0, 8)}...</span>
                      <span style={{
                        color: d.status === 'REVERSED' ? '#10b981' : d.status === 'REJECTED' ? '#ef4444' : '#f59e0b',
                        fontWeight: 700
                      }}>
                        {d.status}
                      </span>
                    </div>
                    <div>Số tiền: {new Intl.NumberFormat('vi-VN').format(d.refundAmount)} đ · {d.reason}</div>
                    {(d.status === 'OPEN' || d.status === 'UNDER_REVIEW') && staff.role === 'MANAGER' && (
                      <div className="inline-actions" style={{ marginTop: '6px' }}>
                        <button
                          className="button button-secondary"
                          style={{ fontSize: '11px', padding: '3px 8px', background: '#10b981', color: '#fff', border: 'none' }}
                          onClick={() => void handleResolveDispute(d.id, 'REFUND')}
                        >
                          Duyệt hoàn tiền
                        </button>
                        <button
                          className="button button-secondary"
                          style={{ fontSize: '11px', padding: '3px 8px', background: '#ef4444', color: '#fff', border: 'none' }}
                          onClick={() => void handleResolveDispute(d.id, 'REJECT')}
                        >
                          Từ chối
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
            {staff.role === 'MANAGER' && (
              <form onSubmit={handleManualReversal} style={{ marginTop: 8, borderTop: '1px solid var(--border-color)', paddingTop: 8 }}>
                <div style={{ fontWeight: 600, fontSize: '12px', marginBottom: 4 }}>Đảo bút toán trực tiếp (Manual Reversal):</div>
                <div className="stack gap-xs">
                  <input
                    style={{ fontSize: '12px', padding: '4px 8px' }}
                    placeholder="Mã Transaction ID"
                    value={manualRevTxId}
                    onChange={(e) => setManualRevTxId(e.target.value)}
                  />
                  <input
                    style={{ fontSize: '12px', padding: '4px 8px' }}
                    placeholder="Lý do đảo bút toán / hoàn tiền"
                    value={manualRevReason}
                    onChange={(e) => setManualRevReason(e.target.value)}
                  />
                  <button type="submit" className="button button-secondary" style={{ fontSize: '11px', padding: '4px 8px' }}>
                    Thực hiện Đảo bút toán
                  </button>
                </div>
              </form>
            )}
          </div>
        ))}
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
        {card('Quản trị Nhân sự chi nhánh (Staff IAM)', staffDirectory, (
          <div className="stack gap-sm">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <strong>{staffDirectory.data?.length ?? 0} cán bộ hệ thống</strong>
              {staff.role === 'MANAGER' && (
                <button
                  className="button button-secondary"
                  style={{ fontSize: '11px', padding: '3px 8px' }}
                  onClick={() => setShowCreateStaff(!showCreateStaff)}
                >
                  {showCreateStaff ? 'Đóng form' : '+ Thêm cán bộ'}
                </button>
              )}
            </div>

            {showCreateStaff && staff.role === 'MANAGER' && (
              <form onSubmit={handleCreateStaff} style={{ background: 'var(--surface-color, rgba(0,0,0,0.02))', padding: '8px', borderRadius: '6px', border: '1px solid var(--border-color)' }}>
                <div style={{ fontWeight: 600, fontSize: '11px', marginBottom: 4 }}>Thêm cán bộ mới:</div>
                <div className="grid grid-2 gap-xs">
                  <input style={{ fontSize: '11px', padding: '3px 6px' }} placeholder="Username" value={newStaffUsername} onChange={(e) => setNewStaffUsername(e.target.value)} />
                  <input style={{ fontSize: '11px', padding: '3px 6px' }} placeholder="Họ và tên" value={newStaffFullName} onChange={(e) => setNewStaffFullName(e.target.value)} />
                  <input style={{ fontSize: '11px', padding: '3px 6px' }} placeholder="Số điện thoại" value={newStaffPhone} onChange={(e) => setNewStaffPhone(e.target.value)} />
                  <input style={{ fontSize: '11px', padding: '3px 6px' }} placeholder="Email" value={newStaffEmail} onChange={(e) => setNewStaffEmail(e.target.value)} />
                  <select style={{ fontSize: '11px', padding: '3px 6px' }} value={newStaffRole} onChange={(e) => setNewStaffRole(e.target.value)}>
                    <option value="TELLER">TELLER (Giao dịch viên)</option>
                    <option value="MANAGER">MANAGER (Kiểm soát viên / Quản lý)</option>
                    <option value="ADMIN">ADMIN (Quản trị viên)</option>
                  </select>
                  <input style={{ fontSize: '11px', padding: '3px 6px' }} placeholder="Chi nhánh (BR_Q1, BR_HK...)" value={newStaffBranch} onChange={(e) => setNewStaffBranch(e.target.value)} />
                </div>
                <button type="submit" className="button button-secondary" style={{ fontSize: '11px', padding: '4px 8px', marginTop: 6 }}>
                  Lưu cán bộ
                </button>
              </form>
            )}

            {staffDirectory.data && staffDirectory.data.length > 0 && (
              <div className="stack gap-xs" style={{ maxHeight: 220, overflowY: 'auto' }}>
                {staffDirectory.data.map((item) => (
                  <div key={item.id} style={{ padding: '6px 8px', border: '1px solid var(--border-color)', borderRadius: '4px', fontSize: '11px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <div style={{ fontWeight: 600 }}>{item.fullName || item.username} (@{item.username})</div>
                      <div style={{ color: 'var(--text-muted)' }}>{item.role} · Chi nhánh: {item.branchId}</div>
                    </div>
                    <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                      <span className={`badge ${item.status === 'ACTIVE' ? 'badge-green' : 'badge-red'}`} style={{ fontSize: '10px' }}>
                        {item.status}
                      </span>
                      {staff.role === 'MANAGER' && item.id !== staff.id && (
                        <div className="inline-actions">
                          <button
                            className="button button-secondary"
                            style={{ fontSize: '10px', padding: '2px 6px', color: item.status === 'ACTIVE' ? '#ef4444' : '#10b981' }}
                            onClick={() => void handleToggleLockStaff(item)}
                          >
                            {item.status === 'ACTIVE' ? 'Khóa' : 'Mở'}
                          </button>
                          <button
                            className="button button-secondary"
                            style={{ fontSize: '10px', padding: '2px 6px' }}
                            onClick={() => void handleResetStaffPassword(item)}
                          >
                            Reset MK
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
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
        {card('Hàng đợi thông báo (DLQ & RabbitMQ)', notificationDlq, (
          <div className="stack gap-sm">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span>DLQ: <strong>{notificationDlq.data?.dlqQueueName || 'notification.events.dlq'}</strong></span>
              <span className={`badge ${notificationDlq.data?.messageCount && notificationDlq.data.messageCount > 0 ? 'badge-red' : 'badge-green'}`}>
                {notificationDlq.data?.messageCount ?? 0} tin lỗi
              </span>
            </div>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              Queue chính: {notificationDlq.data?.mainQueueName || 'notification.events.queue'} ({notificationDlq.data?.mainQueueMessageCount ?? 0} tin)
            </div>
            {staff.role === 'MANAGER' && (
              <div className="inline-actions" style={{ marginTop: '6px' }}>
                <button
                  className="button button-secondary"
                  style={{ fontSize: '11px', padding: '4px 8px' }}
                  onClick={() => void handleRetryDlq()}
                  disabled={!notificationDlq.data?.messageCount}
                >
                  Retry DLQ (50 tin)
                </button>
                <button
                  className="button button-secondary"
                  style={{ fontSize: '11px', padding: '4px 8px', color: '#ef4444' }}
                  onClick={() => void handlePurgeDlq()}
                  disabled={!notificationDlq.data?.messageCount}
                >
                  Xóa sạch DLQ
                </button>
              </div>
            )}
          </div>
        ))}
        {card('Hạ tầng thông báo & Test Push', notificationHealth, (
          <div className="stack gap-sm">
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', fontSize: '12px' }}>
              <span className={`badge ${notificationHealth.data?.websocket?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                WS: {notificationHealth.data?.websocket?.status || 'UNKNOWN'}
              </span>
              <span className={`badge ${notificationHealth.data?.fcm?.status === 'UP' ? 'badge-green' : 'badge-cyan'}`}>
                FCM: {notificationHealth.data?.fcm?.status || 'OFFLINE'}
              </span>
              <span className={`badge ${notificationHealth.data?.rabbitmq?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                RabbitMQ: {notificationHealth.data?.rabbitmq?.status || 'UNKNOWN'}
              </span>
              <span className={`badge ${notificationHealth.data?.kafka?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                Kafka: {notificationHealth.data?.kafka?.status || 'UNKNOWN'}
              </span>
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
              Thiết bị kích hoạt (FCM tokens): <strong>{notificationHealth.data?.activeDeviceTokens ?? 0}</strong>
            </div>
            {staff.role === 'MANAGER' && (
              <form onSubmit={handleSendTestPush} style={{ marginTop: 6, borderTop: '1px solid var(--border-color)', paddingTop: 6 }}>
                <div style={{ fontWeight: 600, fontSize: '11px', marginBottom: 4 }}>Gửi thông báo kiểm thử (Diagnostic Test):</div>
                <div className="stack gap-xs">
                  <input
                    style={{ fontSize: '11px', padding: '3px 6px' }}
                    placeholder="Mã User / Customer ID"
                    value={testPushRecipient}
                    onChange={(e) => setTestPushRecipient(e.target.value)}
                  />
                  <input
                    style={{ fontSize: '11px', padding: '3px 6px' }}
                    placeholder="Tiêu đề thông báo"
                    value={testPushTitle}
                    onChange={(e) => setTestPushTitle(e.target.value)}
                  />
                  <input
                    style={{ fontSize: '11px', padding: '3px 6px' }}
                    placeholder="Nội dung kiểm thử"
                    value={testPushMessage}
                    onChange={(e) => setTestPushMessage(e.target.value)}
                  />
                  <button type="submit" className="button button-secondary" style={{ fontSize: '11px', padding: '3px 8px' }}>
                    Phát tin chẩn đoán
                  </button>
                </div>
              </form>
            )}
          </div>
        ))}
        {card('Trung tâm Báo cáo & Xuất dữ liệu Kế toán', { status: exportingReport ? 'loading' : 'ready' }, (
          <div className="stack gap-sm">
            <p className="text-muted" style={{ fontSize: '11px', margin: 0 }}>
              Xuất chứng từ kế toán, sổ phụ giao dịch và báo cáo kiểm toán phục vụ đối soát định kỳ.
            </p>
            <div className="grid grid-2 gap-xs">
              <button
                className="button button-secondary"
                style={{ fontSize: '11px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}
                onClick={() => void handleDownloadReport(
                  transactionQuery.trim() ? `/api/v1/transactions/export/pdf?walletId=${encodeURIComponent(transactionQuery.trim())}` : '/api/v1/transactions/export/pdf',
                  `statement-${transactionQuery.trim() || 'all'}.pdf`,
                  'Sổ phụ giao dịch PDF'
                )}
                disabled={Boolean(exportingReport)}
              >
                📄 Sổ phụ GD (PDF)
              </button>
              <button
                className="button button-secondary"
                style={{ fontSize: '11px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}
                onClick={() => void handleDownloadReport(
                  transactionQuery.trim() ? `/api/v1/transactions/export/csv?walletId=${encodeURIComponent(transactionQuery.trim())}` : '/api/v1/transactions/export/csv',
                  `statement-${transactionQuery.trim() || 'all'}.csv`,
                  'Sao kê giao dịch CSV'
                )}
                disabled={Boolean(exportingReport)}
              >
                📊 Sao kê GD (CSV)
              </button>
              <button
                className="button button-secondary"
                style={{ fontSize: '11px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}
                onClick={() => void handleDownloadReport(
                  '/api/v1/ledger/reports/journal-entries/export',
                  `journal-entries-${new Date().toISOString().slice(0, 10)}.csv`,
                  'Bút toán Sổ cái kép'
                )}
                disabled={Boolean(exportingReport)}
              >
                📑 Bút toán Sổ cái (CSV)
              </button>
              <button
                className="button button-secondary"
                style={{ fontSize: '11px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}
                onClick={() => void handleDownloadReport(
                  '/api/v1/ledger/reports/accounts/export',
                  `chart-of-accounts-${new Date().toISOString().slice(0, 10)}.csv`,
                  'Danh mục tài khoản kế toán'
                )}
                disabled={Boolean(exportingReport)}
              >
                📋 Danh mục TK (CSV)
              </button>
            </div>
            <button
              className="button button-secondary"
              style={{ fontSize: '11px', padding: '6px 8px', width: '100%' }}
              onClick={() => void handleDownloadReport(
                '/api/v1/ledger/reports/eod-history/export',
                `eod-history-${new Date().toISOString().slice(0, 10)}.csv`,
                'Lịch sử phiên khóa sổ EOD'
              )}
              disabled={Boolean(exportingReport)}
            >
              ⏳ Lịch sử khóa sổ EOD Batches (CSV)
            </button>
            {exportingReport && (
              <div style={{ fontSize: '11px', color: 'var(--brand-primary, #10b981)' }}>
                Đang xuất báo cáo {exportingReport}...
              </div>
            )}
          </div>
        ))}
        {card('Khả năng phục hồi & Sức khỏe vi dịch vụ', resilience, (
          <div className="stack gap-sm">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '12px', fontWeight: 600 }}>Toàn hệ thống:</span>
              <span className={`badge ${resilience.data?.overallStatus === 'HEALTHY' ? 'badge-green' : resilience.data?.overallStatus === 'DEGRADED' ? 'badge-amber' : 'badge-red'}`}>
                {resilience.data?.overallStatus || 'UNKNOWN'}
              </span>
            </div>
            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', fontSize: '11px' }}>
              <span className={`badge ${resilience.data?.database?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                DB Pool: {resilience.data?.database?.activeConnections ?? 0}/{resilience.data?.database?.totalConnections ?? 0}
              </span>
              <span className={`badge ${resilience.data?.redis?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                Redis: {resilience.data?.redis?.status === 'UP' ? `${resilience.data?.redis?.latencyMs ?? 0}ms` : 'OFFLINE'}
              </span>
              <span className={`badge ${resilience.data?.messaging?.rabbitMqStatus === 'UP' ? 'badge-green' : 'badge-red'}`}>
                RabbitMQ: {resilience.data?.messaging?.rabbitMqStatus || 'OFFLINE'}
              </span>
              <span className={`badge ${resilience.data?.messaging?.kafkaStatus === 'UP' ? 'badge-green' : 'badge-red'}`}>
                Kafka: {resilience.data?.messaging?.kafkaStatus || 'OFFLINE'}
              </span>
              <span className={`badge ${resilience.data?.grpc?.status === 'UP' ? 'badge-green' : 'badge-red'}`}>
                gRPC: {resilience.data?.grpc?.status || 'OFFLINE'}
              </span>
            </div>
            {resilience.data?.microservices && (
              <div style={{ fontSize: '11px', borderTop: '1px solid var(--border-color)', paddingTop: 6 }}>
                <div style={{ fontWeight: 600, marginBottom: 4 }}>Trạng thái 6 Microservices:</div>
                <div className="grid grid-2 gap-xs">
                  {Object.entries(resilience.data.microservices).map(([key, svc]) => (
                    <div key={key} style={{ display: 'flex', justifyContent: 'space-between', padding: '3px 6px', background: 'var(--surface-color, rgba(0,0,0,0.02))', borderRadius: '4px' }}>
                      <span style={{ color: 'var(--text-muted)' }}>{svc.name}</span>
                      <span style={{ color: svc.status === 'UP' ? '#10b981' : '#f59e0b', fontWeight: 600 }}>{svc.status}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
