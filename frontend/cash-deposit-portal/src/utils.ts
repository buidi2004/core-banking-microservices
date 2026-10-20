import { CashDeposit } from './types';

export function formatCurrency(amount: number): string {
  return amount.toLocaleString('vi-VN') + ' VND';
}

export function formatDateVi(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('vi-VN') + ' ' + d.toLocaleTimeString('vi-VN');
}

export function numberToVietnameseWords(n: number): string {
  if (n === 0) return 'Không đồng';
  const chuSo = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
  const tien = ['', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ', 'triệu tỷ'];

  function docBaSo(baso: number, showZeroHundred: boolean): string {
    let tram = Math.floor(baso / 100);
    let chuc = Math.floor((baso % 100) / 10);
    let donvi = baso % 10;
    let ketQua = '';

    if (tram > 0 || showZeroHundred) {
      ketQua += ' ' + chuSo[tram] + ' trăm';
    }

    if (chuc > 1) {
      ketQua += ' ' + chuSo[chuc] + ' mươi';
      if (donvi === 1) ketQua += ' mốt';
      else if (donvi === 5) ketQua += ' lăm';
      else if (donvi > 0) ketQua += ' ' + chuSo[donvi];
    } else if (chuc === 1) {
      ketQua += ' mười';
      if (donvi === 1) ketQua += ' một';
      else if (donvi === 5) ketQua += ' lăm';
      else if (donvi > 0) ketQua += ' ' + chuSo[donvi];
    } else if (chuc === 0 && donvi > 0) {
      if (tram > 0 || showZeroHundred) ketQua += ' lẻ ' + chuSo[donvi];
      else ketQua += ' ' + chuSo[donvi];
    }
    return ketQua.trim();
  }

  let str = n.toString();
  let groups: number[] = [];
  while (str.length > 0) {
    groups.unshift(parseInt(str.slice(-3), 10));
    str = str.slice(0, -3);
  }

  let kq = '';
  for (let i = 0; i < groups.length; i++) {
    let g = groups[i];
    let pos = groups.length - 1 - i;
    if (g > 0) {
      let gStr = docBaSo(g, i > 0);
      kq += ' ' + gStr + ' ' + tien[pos];
    }
  }

  kq = kq.trim();
  if (!kq) return 'Không đồng';
  return kq.charAt(0).toUpperCase() + kq.slice(1) + ' đồng chẵn.';
}

export function generateReceiptHash(code: string, amount: number, acc: string): string {
  const seed = code + '-' + amount + '-' + acc + '-' + Date.now();
  let h = 0;
  for (let i = 0; i < seed.length; i++) {
    h = ((h << 5) - h) + seed.charCodeAt(i);
    h |= 0;
  }
  const hex = Math.abs(h).toString(16).padStart(8, '0');
  return 'f8a' + hex + 'e49b2c710d8a9e';
}

export function numberToWordsShort(n: number): string {
  if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(1) + 'B';
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
  return n.toString();
}