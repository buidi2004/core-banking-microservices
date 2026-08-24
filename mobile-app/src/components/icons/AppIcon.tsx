import React from 'react';
import {
  ChevronLeft, Search, Bell, Home, History, QrCode, User, Eye, EyeOff,
  X, Check, ChevronRight, Camera, Upload, Zap, Droplet, Wifi, Phone,
  MessageCircle, Gift, HelpCircle, Landmark, CreditCard, Plus, Share2,
  Copy, AlertTriangle, CheckCircle2, XCircle, ScanLine, ArrowLeft,
  type LucideIcon,
} from 'lucide-react-native';
import { Colors } from '../../theme';

// Chỉ import icon nào thực sự dùng — KHÔNG import cả object `icons` của lucide,
// làm vậy sẽ mất tree-shaking và bundle toàn bộ thư viện.
const ICON_MAP: Record<string, LucideIcon> = {
  back: ChevronLeft,
  arrowLeft: ArrowLeft,
  search: Search,
  notification: Bell,
  home: Home,
  history: History,
  qr: QrCode,
  profile: User,
  eye: Eye,
  eyeOff: EyeOff,
  close: X,
  check: Check,
  chevronRight: ChevronRight,
  camera: Camera,
  upload: Upload,
  electricity: Zap,
  water: Droplet,
  wifi: Wifi,
  phone: Phone,
  chat: MessageCircle,
  gift: Gift,
  help: HelpCircle,
  bank: Landmark,
  card: CreditCard,
  plus: Plus,
  share: Share2,
  copy: Copy,
  warning: AlertTriangle,
  success: CheckCircle2,
  fail: XCircle,
  scanFrame: ScanLine,
};

export type IconName = keyof typeof ICON_MAP;
const SIZE_MAP = { xs: 16, sm: 20, md: 24, lg: 28, xl: 32, xxl: 48, xxxl: 80, huge: 160 } as const;

interface AppIconProps {
  name: IconName;
  size?: keyof typeof SIZE_MAP;
  color?: string;
  strokeWidth?: number;
}

export function AppIcon({
  name,
  size = 'md',
  color = Colors.textPrimary,
  strokeWidth = 1.75,
}: AppIconProps) {
  const Icon = ICON_MAP[name];
  if (!Icon) {
    return null;
  }
  return <Icon size={SIZE_MAP[size]} color={color} strokeWidth={strokeWidth} />;
}