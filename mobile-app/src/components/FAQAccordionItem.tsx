import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';

interface FAQAccordionItemProps {
  question: string;
  answer: string;
}

export const FAQAccordionItem: React.FC<FAQAccordionItemProps> = ({ question, answer }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.header} onPress={() => setIsOpen(!isOpen)}>
        <Text style={styles.question}>{question}</Text>
        <AppIcon name={isOpen ? "chevronRight" : "chevronRight"} size="sm" color={Colors.primary} />
      </TouchableOpacity>
      {isOpen && <Text style={styles.answer}>{answer}</Text>}
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
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.textPrimary,
    marginRight: Spacing.sm,
  },
  answer: {
    fontSize: Typography.caption.fontSize,
    color: Colors.textSecondary,
    lineHeight: 20,
    paddingBottom: Spacing.md,
  },
});