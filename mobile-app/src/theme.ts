// ============================================
// THEME — Central design tokens for E-Wallet
// Import this file everywhere, never hard-code colors/radii/typography
// ============================================

export const Colors = {
  // Background
  bgBase: '#F3F8FC', // --color-surface-alt
  bgGray: '#F3F8FC', 

  // Surface
  surface: '#FFFFFF',

  // Primary palette (Lotus Deep Pink - Hồng Sen Đậm & Hồng Cánh Sen)
  primary: '#D2519D', // --color-primary-500: Hồng sen đậm rực rỡ
  primarySoft: '#FDF2F8', // --color-primary-50: Hồng phấn nhẹ nhàng
  primaryDeep: '#700F43', // --color-primary-900: Hồng sen sẫm quý phái (đáy gradient)
  primary700: '#9D1764', // --color-primary-700
  primary800: 'rgba(157, 23, 100, 0.55)', // --color-primary-800 cho Balance Card glass
  primaryGlow: '#F472B6', // --color-primary-glow: Ánh hồng phát sáng (aura)
  
  // Custom Gradients (Hoa sen lúc nở rộ)
  heroGradStart: '#E4ACB2', // Hồng cánh sen tươi sáng
  heroGradMid: '#D2519D',   // Hồng sen đậm rực rỡ
  heroGradEnd: '#700F43',   // Hồng sen sẫm quý phái
  lotusPink: '#D2519D',
  lotusPetal: '#E4ACB2',

  bannerDeep: '#700F43', 
  navBg: '#D2519D',

  // Text
  textPrimary: '#1A1A1A',
  textSecondary: '#8A93A6',
  textOnDark: '#FFFFFF',
  textOnDarkMuted: 'rgba(255,255,255,0.75)',

  // Status & Accents
  success: '#34C759',
  danger: '#FF3B30',
  warning: '#FF9F0A',
  
  badgeRed: '#E11D48',
  badgeBlueSoft: '#FCE7F3', // Hồng pastel cho badge
  accentYellow: '#FDD349',
  ctaPill: '#F472B6',

  // Glass
  glassTint: 'rgba(255,255,255,0.55)',
  glassBorder: 'rgba(255,255,255,0.65)',

  // Shadow
  shadowColor: '#D2519D',
  shadowTransparent: 'transparent',

  // Status chip soft backgrounds
  successSoft: '#D1FAD1',
  dangerSoft: '#FFD4D3',
  warningSoft: '#FFF3CD',

  // Status chip text colors
  successText: '#1A7A37',
  dangerText: '#C0392B',
  warningText: '#B36B00',

  // Promo/special gradients
  promoGradStart: '#FF6B52',
  promoGradEnd: '#FF4E50',

  // Device management icon gradient
  deviceIconGradStart: '#DCEBFF',
  deviceIconGradEnd: '#E8F4FF',

  // White (for icons on dark backgrounds)
  white: '#FFFFFF',

  // Black (for camera screen)
  black: '#000000',

  // Drag handle / muted UI elements
  dragHandleBg: '#D0D5DD',

  // Overlay dark (for banners)
  overlayDark: 'rgba(0,0,0,0.5)',
  
  // Custom glass/rgba overlays
  glassLight: 'rgba(255,255,255,0.3)',
  glassMedium: 'rgba(255,255,255,0.5)',
  glassStrong: 'rgba(255,255,255,0.7)',
  glassHeavy: 'rgba(255,255,255,0.8)',
  glassOpaque: 'rgba(255,255,255,0.9)',
  glassSolid: 'rgba(255,255,255,0.95)',
} as const;

export const Opacity = {
  disabled: 0.5,
  muted: 0.8,
} as const;

export const Radius = {
  none: 0,
  xs: 6,
  sm: 12,
  md: 20,
  lg: 28,
  pill: 999,
} as const;

export const Spacing = {
  xxs: 4,
  xs: 8,
  sm: 12,
  md: 16,
  lg: 20,
  xl: 24,
  xxl: 32,
  xxxl: 40,
} as const;

export const Shadows = {
  card: {
    shadowColor: Colors.shadowColor,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 4,
  },
  elevated: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 24,
    elevation: 6,
  },
  hero: {
    shadowColor: Colors.shadowColor,
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.22,
    shadowRadius: 24,
    elevation: 8,
  },
  transparent: {
    shadowColor: Colors.shadowTransparent,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
  },
};

// ============================================
// TYPOGRAPHY TOKENS — Complete font scale
// All font sizes and families must use these tokens
// ============================================

export const Typography = {
  // Balance Amount
  balanceLarge: {
    fontFamily: 'Manrope_700Bold',
    fontSize: 28,
    color: Colors.textOnDark,
    fontVariant: ['tabular-nums'] as const,
    lineHeight: 34,
  },
  // Display/Balance (largest, for amounts and balances)
  displayLarge: {
    fontFamily: 'Manrope_800ExtraBold',
    fontSize: 40,
    color: Colors.textPrimary,
    fontVariant: ['tabular-nums'] as const,
    lineHeight: 48,
  },
  display: {
    fontFamily: 'Manrope_800ExtraBold',
    fontSize: 32,
    color: Colors.textPrimary,
    fontVariant: ['tabular-nums'] as const,
    lineHeight: 40,
  },
  
  // Headings
  headingXl: {
    fontFamily: 'Inter_700Bold',
    fontSize: 24,
    color: Colors.textPrimary,
    lineHeight: 32,
  },
  headingLg: {
    fontFamily: 'Inter_700Bold',
    fontSize: 20,
    color: Colors.textPrimary,
    lineHeight: 28,
  },
  heading: {
    fontFamily: 'Inter_700Bold',
    fontSize: 17,
    color: Colors.textPrimary,
    lineHeight: 24,
  },
  headingSm: {
    fontFamily: 'Inter_600SemiBold', // Mua sắm giải trí (15-16px semi-bold)
    fontSize: 16,
    color: Colors.textPrimary,
    lineHeight: 22,
  },
  
  // Body text
  bodyLg: {
    fontFamily: 'Inter_400Regular',
    fontSize: 18,
    color: Colors.textPrimary,
    lineHeight: 26,
  },
  body: {
    fontFamily: 'Inter_400Regular',
    fontSize: 15,
    color: Colors.textPrimary,
    lineHeight: 22,
  },
  bodyMd: {
    fontFamily: 'Inter_500Medium', // Action names
    fontSize: 13,
    color: Colors.textPrimary,
    lineHeight: 18,
  },
  bodySm: {
    fontFamily: 'Inter_400Regular',
    fontSize: 12, // Tên icon dịch vụ
    color: Colors.textPrimary,
    lineHeight: 16,
  },
  
  // Caption/labels
  caption: {
    fontFamily: 'Inter_500Medium',
    fontSize: 12,
    color: Colors.textSecondary,
    lineHeight: 16,
  },
  captionSm: {
    fontFamily: 'Inter_500Medium',
    fontSize: 11, // Label bottom nav
    color: Colors.textSecondary,
    lineHeight: 14,
  },
  captionXs: {
    fontFamily: 'Inter_500Medium',
    fontSize: 10,
    color: Colors.textSecondary,
    lineHeight: 14,
  },
  badgeSmall: {
    fontFamily: 'Inter_700Bold',
    fontSize: 9,
    letterSpacing: 0.3,
    color: Colors.white,
    lineHeight: 12,
  },
  
  // Button text
  button: {
    fontFamily: 'Inter_600SemiBold',
    fontSize: 15,
    color: Colors.white,
    lineHeight: 20,
  },
  buttonSm: {
    fontFamily: 'Inter_600SemiBold',
    fontSize: 13,
    color: Colors.primary,
    lineHeight: 18,
  },
} as const;

// Font family names for direct usage when needed
export const FontFamily = {
  manropeBold: 'Manrope_700Bold',
  manropeExtraBold: 'Manrope_800ExtraBold',
  interRegular: 'Inter_400Regular',
  interMedium: 'Inter_500Medium',
  interSemiBold: 'Inter_600SemiBold',
  interBold: 'Inter_700Bold',
} as const;

// Grouped list divider color
export const ListDivider = {
  color: Colors.primarySoft,
  thickness: 1,
};
