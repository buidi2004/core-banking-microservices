import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface FAQAccordionItemProps {
  question: string;
  answer: string;
}

export const FAQAccordionItem: React.FC<FAQAccordionItemProps> = ({ question, answer }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.header} onPress={() => setIsOpen(!isOpen)}>
        <AppText variant="body" style={styles.question}>{question}</AppText>
        <AppIcon name={isOpen ? "chevronRight" : "chevronRight"} size="sm" color={Colors.primary} />
      </TouchableOpacity>
      {isOpen && <AppText variant="caption" style={styles.answer}>{answer}</AppText>}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.surface,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
    paddingHorizontal: Spacing.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.md,
  },
  question: {
    flex: 1,
    color: Colors.textPrimary,
    marginRight: Spacing.sm,
  },
  answer: {
    color: Colors.textSecondary,
    lineHeight: 20,
    paddingBottom: Spacing.md,
  },
});