import React from 'react';
import { Role } from '../types';
import { UserCheck, ShieldCheck } from 'lucide-react';

interface RoleSwitcherProps {
  role: Role;
  onSwitch: (role: Role) => void;
}

export function RoleSwitcher({ role, onSwitch }: RoleSwitcherProps) {
  return (
    <div className="role-switcher-box">
      <button
        type="button"
        className={`role-btn ${role === 'TELLER' ? 'active' : ''}`}
        onClick={() => onSwitch('TELLER')}
      >
        <UserCheck size={14} />
        <span>Giao dịch viên (Teller)</span>
      </button>
      <button
        type="button"
        className={`role-btn ${role === 'MANAGER' ? 'active' : ''}`}
        onClick={() => onSwitch('MANAGER')}
      >
        <ShieldCheck size={14} />
        <span>Kiểm soát viên (Manager)</span>
      </button>
    </div>
  );
}