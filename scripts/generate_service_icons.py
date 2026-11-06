#!/usr/bin/env python3
import os
import subprocess

svg_dir = "/home/buidi/Tài liệu/core-banking-microservices/mobile/assets/images/service-icons/vector_drawn"
png_dir = "/home/buidi/Tài liệu/core-banking-microservices/mobile/assets/images/service-icons/vector_drawn_png512"
os.makedirs(svg_dir, exist_ok=True)
os.makedirs(png_dir, exist_ok=True)

svgs = {}

# 1. VUA XỔ SỐ
svgs["01_vua_xo_so.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow1" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.12"/>
    </filter>
    <linearGradient id="wheelGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#E1F5FE"/>
    </linearGradient>
    <linearGradient id="redSphere" x1="30%" y1="20%" x2="80%" y2="90%">
      <stop offset="0%" stop-color="#FF5252"/>
      <stop offset="60%" stop-color="#D32F2F"/>
      <stop offset="100%" stop-color="#8B0000"/>
    </linearGradient>
    <linearGradient id="ribbonGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#C62828"/>
      <stop offset="50%" stop-color="#E53935"/>
      <stop offset="100%" stop-color="#B71C1C"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="#FFFFFF" filter="url(#shadow1)"/>
  
  <!-- Outer Wheel -->
  <circle cx="256" cy="240" r="145" fill="url(#wheelGrad)" stroke="#1976D2" stroke-width="12"/>
  <circle cx="256" cy="240" r="130" fill="none" stroke="#BBDEFB" stroke-width="4" stroke-dasharray="14 10"/>
  
  <!-- Wheel Segments -->
  <g opacity="0.85">
    <path d="M 256 110 L 256 240" stroke="#1E88E5" stroke-width="4"/>
    <path d="M 126 240 L 256 240" stroke="#1E88E5" stroke-width="4"/>
    <path d="M 386 240 L 256 240" stroke="#1E88E5" stroke-width="4"/>
    <path d="M 164 148 L 256 240" stroke="#1E88E5" stroke-width="4"/>
    <path d="M 348 148 L 256 240" stroke="#1E88E5" stroke-width="4"/>
  </g>

  <!-- Number 9 Sphere (Top Center) -->
  <circle cx="256" cy="180" r="46" fill="url(#redSphere)" stroke="#FFFFFF" stroke-width="4"/>
  <ellipse cx="244" cy="164" rx="16" ry="8" fill="#FFFFFF" opacity="0.4" transform="rotate(-30 244 164)"/>
  <text x="256" y="196" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="44" fill="#FFFFFF">9</text>

  <!-- Side Lottery Balls -->
  <circle cx="165" cy="225" r="28" fill="#FFC107" stroke="#FFFFFF" stroke-width="3"/>
  <text x="165" y="235" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="26" fill="#3E2723">7</text>
  
  <circle cx="347" cy="225" r="28" fill="#00C853" stroke="#FFFFFF" stroke-width="3"/>
  <text x="347" y="235" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="26" fill="#FFFFFF">8</text>

  <!-- Banner Ribbon (VUA XỔ SỐ) -->
  <g transform="translate(0, 15)">
    <path d="M 100 295 L 140 270 L 140 330 L 100 350 Z" fill="#8B0000"/>
    <path d="M 412 295 L 372 270 L 372 330 L 412 350 Z" fill="#8B0000"/>
    <path d="M 125 290 Q 256 250 387 290 L 387 345 Q 256 305 125 345 Z" fill="url(#ribbonGrad)" stroke="#FFD54F" stroke-width="6"/>
    <text x="256" y="324" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="34" fill="#FFEB3B" letter-spacing="2">VUA XỔ SỐ</text>
  </g>
</svg>"""

# 2. VÉ SỐ VIETLOTT SMS
svgs["02_ve_so_vietlott.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow2" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.12"/>
    </filter>
    <linearGradient id="vietlottRed" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF333A"/>
      <stop offset="60%" stop-color="#ED1C24"/>
      <stop offset="100%" stop-color="#C7000B"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="#FFFFFF" filter="url(#shadow2)"/>

  <!-- Red Vietlott Circle -->
  <circle cx="256" cy="256" r="160" fill="url(#vietlottRed)"/>
  <circle cx="256" cy="256" r="158" fill="none" stroke="#FFA4A7" stroke-width="3" opacity="0.5"/>

  <!-- Vietlott Emblem (Lotus / Star Ribbon Swirl) -->
  <g transform="translate(256, 200) scale(1.15)">
    <path d="M 0,-48 C 16,-48 32,-36 36,-20 C 26,-24 14,-22 4,-14 C -6,-6 -10,6 -8,18 C -14,10 -16,-2 -14,-14 C -12,-30 -4,-48 0,-48 Z" fill="#FFFFFF"/>
    <path d="M 46,-15 C 50,0 44,18 30,28 C 24,18 16,14 4,14 C -8,14 -18,22 -24,32 C -20,22 -18,10 -10,2 C 2,-10 26,-18 46,-15 Z" fill="#FFFFFF"/>
    <path d="M 28,39 C 14,49 -4,50 -20,40 C -12,34 -8,24 -8,12 C -8,0 -16,-10 -26,-16 C -18,-14 -6,-10 2,-4 C 14,6 24,24 28,39 Z" fill="#FFFFFF"/>
    <path d="M -28,39 C -42,30 -48,12 -42,-4 C -34,2 -24,4 -14,-2 C -4,-8 0,-20 0,-32 C -4,-22 -12,-16 -22,-14 C -36,-10 -46,2 -28,39 Z" fill="#FFFFFF"/>
    <path d="M -46,-15 C -44,-32 -30,-44 -14,-46 C -18,-36 -16,-26 -8,-18 C 0,-10 8,-8 18,-10 C 10,-4 2,-2 -8,4 C -22,12 -38,4 -46,-15 Z" fill="#FFFFFF"/>
    <circle cx="0" cy="0" r="7" fill="#FFFFFF"/>
  </g>

  <!-- Vietlott Text -->
  <text x="256" y="260" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="700" font-size="20" fill="#FFFFFF" letter-spacing="1.5" opacity="0.95">Vietlott</text>

  <!-- SMS Text -->
  <text x="256" y="340" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="72" fill="#FFFFFF" letter-spacing="4">SMS</text>
</svg>"""

# 3. DATA 4G / NẠP TIỀN
svgs["03_data_4g_nap_tien.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow3" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.12"/>
    </filter>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="#FFFFFF" filter="url(#shadow3)"/>

  <!-- Top: vinaphone -->
  <g transform="translate(256, 175)">
    <text x="0" y="0" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="800" font-size="44" fill="#00A3E0" letter-spacing="-0.5">vinaphone</text>
  </g>

  <!-- Middle: 4G with WiFi -->
  <g transform="translate(256, 256)">
    <text x="-6" y="16" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="68" fill="#FF6F00">4G</text>
    <path d="M -30 -16 A 14 14 0 0 1 -6 -16" fill="none" stroke="#FF8F00" stroke-width="4.5" stroke-linecap="round"/>
    <path d="M -38 -24 A 24 24 0 0 1 2 -24" fill="none" stroke="#FFA000" stroke-width="4.5" stroke-linecap="round"/>
    <path d="M -46 -32 A 34 34 0 0 1 10 -32" fill="none" stroke="#FFB300" stroke-width="4.5" stroke-linecap="round"/>
  </g>

  <!-- Bottom: mobifone -->
  <g transform="translate(256, 345)">
    <text x="0" y="0" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="800" font-size="44" fill="#0055A5" letter-spacing="-0.5">mobifone</text>
    <circle cx="-1" cy="-35" r="5.5" fill="#E60000"/>
  </g>
</svg>"""

# 4. VÉ MÁY BAY SỐ
svgs["04_ve_may_bay_so.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow4" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#005580" flood-opacity="0.30"/>
    </filter>
    <linearGradient id="bgCyan" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00C4E6"/>
      <stop offset="50%" stop-color="#0096C7"/>
      <stop offset="100%" stop-color="#0077B6"/>
    </linearGradient>
    <linearGradient id="goldPlane" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFF176"/>
      <stop offset="50%" stop-color="#FFD54F"/>
      <stop offset="100%" stop-color="#FFA000"/>
    </linearGradient>
    <linearGradient id="wingShadow" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFB300"/>
      <stop offset="100%" stop-color="#E65100"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="url(#bgCyan)" filter="url(#shadow4)"/>
  
  <!-- Contrail curves -->
  <path d="M 80 360 C 140 340 220 310 320 220" fill="none" stroke="#FFFFFF" stroke-width="6" opacity="0.35" stroke-linecap="round"/>
  <path d="M 120 390 C 180 370 250 330 360 250" fill="none" stroke="#FFFFFF" stroke-width="4" opacity="0.25" stroke-linecap="round"/>

  <!-- Stars -->
  <g fill="#FFF59D">
    <path d="M 130 150 Q 140 150 140 140 Q 140 150 150 150 Q 140 150 140 160 Q 140 150 130 150 Z"/>
    <path d="M 390 120 Q 398 120 398 112 Q 398 120 406 120 Q 398 120 398 128 Q 398 120 390 120 Z"/>
    <path d="M 390 310 Q 396 310 396 304 Q 396 310 402 310 Q 396 310 396 316 Q 396 310 390 310 Z"/>
    <circle cx="110" cy="220" r="3.5" opacity="0.7"/>
    <circle cx="340" cy="110" r="4.5" opacity="0.8"/>
  </g>

  <!-- Golden Jet Airplane -->
  <g transform="translate(256, 256) rotate(-28)">
    <path d="M -15 -18 L -30 -115 L 20 -118 L 18 -18 Z" fill="url(#goldPlane)"/>
    <path d="M -15 -18 L 18 -18 L 12 -28 Z" fill="url(#wingShadow)"/>
    <rect x="-10" y="-80" width="16" height="34" rx="7" fill="url(#wingShadow)"/>

    <path d="M -10 18 L 15 125 L 55 120 L 25 18 Z" fill="url(#wingShadow)"/>
    <rect x="18" y="55" width="16" height="34" rx="7" fill="url(#wingShadow)"/>

    <path d="M -110 -8 L -145 -55 L -125 -55 L -95 -5 Z" fill="url(#goldPlane)"/>
    <path d="M -110 8 L -135 48 L -115 48 L -95 5 Z" fill="url(#wingShadow)"/>
    <path d="M -85 0 L -140 0 L -125 -42 L -95 -25 Z" fill="url(#goldPlane)"/>

    <path d="M -130 0 C -110 -18 60 -18 135 0 C 60 18 -110 18 -130 0 Z" fill="url(#goldPlane)"/>
    <path d="M 70 -12 C 110 -8 135 0 135 0 C 135 0 110 8 70 12 Z" fill="#FFF9C4" opacity="0.6"/>
    <path d="M 95 -6 L 112 -2 L 112 2 L 95 6 Z" fill="#005580" opacity="0.85"/>
  </g>
</svg>"""

# 5. VÉ MÁY BAY (SMEDIA)
svgs["05_ve_may_bay.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow5" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.12"/>
    </filter>
    <linearGradient id="planeBlue" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#40C4FF"/>
      <stop offset="50%" stop-color="#0288D1"/>
      <stop offset="100%" stop-color="#01579B"/>
    </linearGradient>
    <linearGradient id="planeShadow" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0277BD"/>
      <stop offset="100%" stop-color="#004C8C"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="#FFFFFF" filter="url(#shadow5)"/>

  <ellipse cx="250" cy="285" rx="110" ry="16" fill="#000000" opacity="0.08"/>

  <g transform="translate(250, 210) rotate(-16) scale(1.15)">
    <path d="M -10 -15 L -20 -95 L 18 -98 L 18 -15 Z" fill="url(#planeBlue)"/>
    <rect x="-8" y="-70" width="14" height="28" rx="6" fill="url(#planeShadow)"/>

    <path d="M -8 15 L 15 105 L 48 100 L 22 15 Z" fill="url(#planeShadow)"/>
    <rect x="18" y="50" width="14" height="28" rx="6" fill="url(#planeShadow)"/>

    <path d="M -90 -6 L -120 -45 L -105 -45 L -75 -4 Z" fill="url(#planeBlue)"/>
    <path d="M -90 6 L -115 40 L -100 40 L -75 4 Z" fill="url(#planeShadow)"/>
    <path d="M -70 0 L -115 0 L -105 -35 L -80 -20 Z" fill="url(#planeBlue)"/>

    <path d="M -115 0 C -95 -16 50 -16 115 0 C 50 16 -95 16 -115 0 Z" fill="url(#planeBlue)"/>
    <path d="M -80 -8 C 0 -12 70 -6 105 0 C 70 2 0 4 -80 0 Z" fill="#FFFFFF" opacity="0.4"/>
    <path d="M 85 -5 L 100 -1 L 100 1 L 85 5 Z" fill="#FFFFFF" opacity="0.9"/>
  </g>

  <!-- Wordmark: SMEDIA -->
  <g transform="translate(256, 350)">
    <text x="-95" y="0" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="44" fill="#E65100">S</text>
    <text x="-65" y="0" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="800" font-size="44" fill="#00838F" letter-spacing="4">MEDIA</text>
  </g>
</svg>"""

# 6. DATA 4G / THẺ GAME
svgs["06_data_4g_the_game.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow6" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#311B92" flood-opacity="0.35"/>
    </filter>
    <linearGradient id="bgPurple" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4A148C"/>
      <stop offset="60%" stop-color="#6A1B9A"/>
      <stop offset="100%" stop-color="#8E24AA"/>
    </linearGradient>
    <linearGradient id="goldAccent" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFF176"/>
      <stop offset="100%" stop-color="#FFD54F"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="url(#bgPurple)" filter="url(#shadow6)"/>

  <!-- Top: 4G with WiFi Bars -->
  <g transform="translate(256, 195)">
    <path d="M -90 -45 A 20 20 0 0 1 -55 -45" fill="none" stroke="#FFD54F" stroke-width="6" stroke-linecap="round"/>
    <path d="M -102 -58 A 35 35 0 0 1 -43 -58" fill="none" stroke="#FFE082" stroke-width="6" stroke-linecap="round"/>
    <text x="-4" y="0" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="92" fill="#FFFFFF" letter-spacing="-2">4G</text>
  </g>

  <!-- Middle: Glowing Gold X / Divider -->
  <g transform="translate(256, 255)">
    <text x="-32" y="2" text-anchor="middle" font-family="Arial, sans-serif" font-weight="900" font-size="28" fill="url(#goldAccent)">✕</text>
    <text x="18" y="0" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="26" fill="url(#goldAccent)" letter-spacing="2">THẺ</text>
  </g>

  <!-- Bottom: GAME -->
  <g transform="translate(256, 345)">
    <text x="0" y="0" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="76" fill="#FFFFFF" letter-spacing="6">GAME</text>
  </g>
</svg>"""

# 7. VẬN SỐ (THÁI CỰC ĐỒ / YIN-YANG)
svgs["07_van_so.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow7" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.35"/>
    </filter>
    <linearGradient id="bgMidnight" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0F172A"/>
      <stop offset="50%" stop-color="#1E293B"/>
      <stop offset="100%" stop-color="#0A0F1D"/>
    </linearGradient>
    <linearGradient id="pearlWhite" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="80%" stop-color="#F1F5F9"/>
      <stop offset="100%" stop-color="#E2E8F0"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="url(#bgMidnight)" filter="url(#shadow7)"/>

  <!-- Halo -->
  <circle cx="256" cy="256" r="158" fill="none" stroke="#334155" stroke-width="4" opacity="0.6"/>
  <circle cx="256" cy="256" r="168" fill="none" stroke="#64748B" stroke-width="2" stroke-dasharray="12 16" opacity="0.4"/>

  <!-- Yin-Yang Base Circle: Dark Navy Half -->
  <circle cx="256" cy="256" r="140" fill="#0A0F1D" stroke="#334155" stroke-width="3"/>

  <!-- White Pearl Half (Yang S-Curve) -->
  <path d="M 256 116 
           A 140 140 0 0 1 256 396 
           A 70 70 0 0 1 256 256 
           A 70 70 0 0 0 256 116 Z" 
        fill="url(#pearlWhite)"/>

  <circle cx="256" cy="186" r="24" fill="#0A0F1D"/>
  <circle cx="256" cy="326" r="24" fill="url(#pearlWhite)"/>
</svg>"""

# 8. XEM THÊM DỊCH VỤ (GRID 4 Ô + BADGE 99)
svgs["08_xem_them_dich_vu.svg"] = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <filter id="shadow8" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.10"/>
    </filter>
    <filter id="badgeShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#D32F2F" flood-opacity="0.4"/>
    </filter>
    <linearGradient id="blueGridGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1E88E5"/>
      <stop offset="100%" stop-color="#1565C0"/>
    </linearGradient>
    <linearGradient id="badgeRed" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF5252"/>
      <stop offset="100%" stop-color="#D32F2F"/>
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="432" height="432" rx="104" fill="#FFFFFF" stroke="#E3F2FD" stroke-width="6" filter="url(#shadow8)"/>

  <!-- 2x2 App Squares Grid -->
  <g fill="none" stroke="url(#blueGridGrad)" stroke-width="22" stroke-linecap="round" stroke-linejoin="round">
    <rect x="156" y="156" width="76" height="76" rx="18" fill="none"/>
    <rect x="280" y="156" width="76" height="76" rx="18" fill="none"/>
    <rect x="156" y="280" width="76" height="76" rx="18" fill="none"/>
    <circle cx="318" cy="318" r="38" fill="none"/>
  </g>

  <!-- Red Notification Badge (Bottom Right: 99) -->
  <g transform="translate(372, 372)" filter="url(#badgeShadow)">
    <circle cx="0" cy="0" r="54" fill="url(#badgeRed)" stroke="#FFFFFF" stroke-width="8"/>
    <text x="0" y="16" text-anchor="middle" font-family="'Be Vietnam Pro', Arial, sans-serif" font-weight="900" font-size="48" fill="#FFFFFF" letter-spacing="-1">99</text>
  </g>
</svg>"""

for fname, content in svgs.items():
    svg_path = os.path.join(svg_dir, fname)
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    png_name = fname.replace(".svg", ".png")
    png_path = os.path.join(png_dir, png_name)
    
    cmd = ["rsvg-convert", "-w", "512", "-h", "512", "-f", "png", "-o", png_path, svg_path]
    subprocess.run(cmd, check=True)
    print(f"✓ Rendered: {fname} -> {png_name} (512x512 PNG)")

print("\nAll 8 Vector SVGs and 512x512 Master PNGs generated successfully!")

