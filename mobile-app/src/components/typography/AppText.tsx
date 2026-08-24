import React from 'react';
import { TextProps } from 'react-native';
import { Typography } from '../../theme';

type Variant = keyof typeof Typography;

interface AppTextProps extends TextProps {
  variant?: Variant;
}

export function AppText({ variant = 'body', style, ...rest }: AppTextProps) {
  const variantStyle = Typography[variant];
  return (
    <AppText
      style={[variantStyle as any, style]}
      {...rest}
    />
  );
}
