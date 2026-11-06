/**
 * Real-time STOMP over Native WebSocket Client dành cho Web Admin Portal.
 * Kết nối trực tiếp tới API Gateway (/ws-native) -> Notification Service.
 * Tự động đăng ký các topic:
 *  - /topic/admin/notifications (thông báo dành cho Admin/Teller)
 *  - /topic/transactions (biến động giao dịch nạp / chuyển / vay toàn hệ thống)
 * Hỗ trợ tự động kết nối lại (Auto-reconnect with exponential backoff).
 */

export interface RealtimeNotification {
  transactionId?: string;
  type?: string;
  status?: string;
  walletId?: string;
  amount?: number;
  currency?: string;
  newBalance?: number;
  timestamp?: string;
  title?: string;
  body?: string;
  note?: string;
  accountNumber?: string;
  customerName?: string;
}

type NotificationCallback = (payload: RealtimeNotification) => void;

class RealtimeNotificationManager {
  private static instance: RealtimeNotificationManager;
  private ws: WebSocket | null = null;
  private isConnected: boolean = false;
  private reconnectTimer: any = null;
  private heartbeatTimer: any = null;
  private callbacks: Set<NotificationCallback> = new Set();
  private reconnectDelay = 2000;

  private constructor() {}

  public static getInstance(): RealtimeNotificationManager {
    if (!RealtimeNotificationManager.instance) {
      RealtimeNotificationManager.instance = new RealtimeNotificationManager();
    }
    return RealtimeNotificationManager.instance;
  }

  public subscribe(callback: NotificationCallback): () => void {
    this.callbacks.add(callback);
    if (!this.isConnected && !this.ws) {
      this.connect();
    }
    return () => {
      this.callbacks.delete(callback);
    };
  }

  public connect(): void {
    if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
      return;
    }

    try {
      const isHttps = window.location.protocol === 'https:';
      const wsProtocol = isHttps ? 'wss:' : 'ws:';
      const wsUrl = `${wsProtocol}//${window.location.host}/ws-native`;

      console.log('[Realtime STOMP Web] Đang kết nối tới:', wsUrl);
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('[Realtime STOMP Web] WebSocket mở thành công. Đang gửi STOMP CONNECT...');
        const connectFrame = `CONNECT\naccept-version:1.1,1.2\nheart-beat:10000,10000\n\n\x00`;
        this.ws?.send(connectFrame);
      };

      this.ws.onmessage = (event) => {
        this.handleMessage(event.data);
      };

      this.ws.onerror = (err) => {
        console.warn('[Realtime STOMP Web] Lỗi WebSocket:', err);
      };

      this.ws.onclose = () => {
        console.log('[Realtime STOMP Web] WebSocket đã đóng. Đang lên lịch kết nối lại...');
        this.cleanup();
        this.scheduleReconnect();
      };
    } catch (e) {
      console.warn('[Realtime STOMP Web] Không thể khởi tạo kết nối:', e);
      this.scheduleReconnect();
    }
  }

  private handleMessage(data: string): void {
    if (!data || data === '\n' || data === '\r\n') {
      return; // Heartbeat ping
    }

    // Parse STOMP frames (ngăn cách bởi \x00)
    const frames = data.split('\x00');
    for (const rawFrame of frames) {
      const frame = rawFrame.trim();
      if (!frame) continue;

      if (frame.startsWith('CONNECTED')) {
        console.log('[Realtime STOMP Web] STOMP CONNECTED! Đăng ký lắng nghe các topic...');
        this.isConnected = true;
        this.reconnectDelay = 2000;
        this.startHeartbeat();

        // 1. Subscribe topic admin notifications
        this.sendSubscribe('/topic/admin/notifications', 'sub-admin-0');
        // 2. Subscribe topic broadcast transactions
        this.sendSubscribe('/topic/transactions', 'sub-tx-1');
      } else if (frame.startsWith('MESSAGE')) {
        this.handleStompMessageFrame(frame);
      }
    }
  }

  private sendSubscribe(destination: string, id: string): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    const subFrame = `SUBSCRIBE\nid:${id}\ndestination:${destination}\nack:auto\n\n\x00`;
    this.ws.send(subFrame);
    console.log(`[Realtime STOMP Web] Đã đăng ký topic: ${destination}`);
  }

  private handleStompMessageFrame(frame: string): void {
    try {
      // Tách headers và body (ngăn cách bởi 2 ký tự xuống dòng liên tiếp)
      const parts = frame.split(/\r?\n\r?\n/);
      if (parts.length < 2) return;

      const bodyText = parts.slice(1).join('\n\n').replace(/\x00+$/, '').trim();
      if (!bodyText) return;

      const payload = JSON.parse(bodyText);
      console.log('[Realtime STOMP Web] Nhận thông báo Realtime:', payload);

      // Phát cho tất cả callbacks đã đăng ký
      this.callbacks.forEach((cb) => {
        try {
          cb(payload);
        } catch (err) {
          console.error('[Realtime STOMP Web] Callback error:', err);
        }
      });
    } catch (e) {
      console.warn('[Realtime STOMP Web] Lỗi bóc tách frame STOMP:', e);
    }
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send('\n'); // STOMP Heartbeat
      }
    }, 10000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  private cleanup(): void {
    this.isConnected = false;
    this.stopHeartbeat();
    if (this.ws) {
      this.ws.onopen = null;
      this.ws.onmessage = null;
      this.ws.onerror = null;
      this.ws.onclose = null;
      this.ws = null;
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.reconnectDelay = Math.min(this.reconnectDelay * 1.5, 15000);
      this.connect();
    }, this.reconnectDelay);
  }
}

export const realtimeNotificationManager = RealtimeNotificationManager.getInstance();

