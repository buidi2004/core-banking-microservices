import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView, Image } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { EmptyState } from '../components/EmptyState';
import { SearchBar } from '../components/SearchBar';
import { AppText } from '../components/typography/AppText';

interface SearchScreenProps {
  navigation: any;
}

const recentSearches = ['Starbucks', 'Grab', 'Tiền điện'];
const suggestedContacts = [
  { id: '1', name: 'Nguyễn Văn A', avatar: 'https://i.pravatar.cc/100?img=1' },
  { id: '2', name: 'Trần Thị B', avatar: 'https://i.pravatar.cc/100?img=2' },
  { id: '3', name: 'Lê Văn C', avatar: 'https://i.pravatar.cc/100?img=3' },
];

export default function SearchScreen({ navigation }: SearchScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [isFocused, setIsFocused] = useState(false);

  return (
    <SafeAreaView style={styles.container}>
      {/* Search bar - full width */}
      <View style={styles.searchContainer}>
        <SearchBar
          value={searchQuery}
          onChangeText={setSearchQuery}
          placeholder="Tìm kiếm..."
          showCancel={isFocused}
          onCancel={() => {
            setIsFocused(false);
            setSearchQuery('');
          }}
        />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {!searchQuery ? (
          <>
            {/* Recent searches */}
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <AppText style={styles.sectionTitle}>Tìm kiếm gần đây</AppText>
                <TouchableOpacity>
                  <AppText style={styles.clearAll}>Xoá hết</AppText>
                </TouchableOpacity>
              </View>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipScroll}>
                {recentSearches.map((search) => (
                  <TouchableOpacity key={search} style={styles.chip}>
                    <AppText style={styles.chipText}>{search}</AppText>
                      <AppIcon name="close" size="xs" color={Colors.textSecondary} />
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            {/* Suggested contacts */}
            <View style={styles.section}>
              <AppText style={styles.sectionTitle}>Liên hệ gợi ý</AppText>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.contactsScroll}>
                {suggestedContacts.map((contact) => (
                  <TouchableOpacity key={contact.id} style={styles.contactItem}>
                    <Image source={{ uri: contact.avatar }} style={styles.contactAvatar} />
                    <AppText style={styles.contactName}>{contact.name}</AppText>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            {/* Quick actions */}
            <View style={styles.section}>
              <AppText style={styles.sectionTitle}>Truy cập nhanh</AppText>
              <View style={styles.quickActions}>
                {[
                  { icon: 'swap-horizontal', label: 'Chuyển tiền' },
                  { icon: 'qr-code', label: 'Quét QR' },
                  { icon: 'wallet', label: 'Nạp tiền' },
                  { icon: 'cash', label: 'Rút tiền' },
                ].map((action, i) => (
                  <TouchableOpacity key={i} style={styles.quickAction}>
                    <View style={styles.quickActionIcon}>
                        <AppIcon name={action.icon as any} size="md" color={Colors.primary} />
                    </View>
                    <AppText style={styles.quickActionLabel}>{action.label}</AppText>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          </>
        ) : (
          <View style={styles.resultsContainer}>
            <EmptyState
              icon="search-outline"
              title={`Không tìm thấy kết quả cho "${searchQuery}"`}
              subtitle="Thử tìm kiếm với từ khóa khác"
            />
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  searchContainer: {
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.md,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.md,
  },
  section: {
    marginBottom: Spacing.xl,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.sm,
  },
  sectionTitle: {
    
    color: Colors.textPrimary,
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.sm,
  },
  clearAll: {
    
    color: Colors.danger,
    },
  chipScroll: {
    paddingHorizontal: Spacing.lg,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: Radius.pill,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    marginRight: Spacing.sm,
    ...Shadows.card,
  },
  chipText: {
    
    color: Colors.textPrimary,
  },
  chipClose: {
    marginLeft: Spacing.sm,
  },
  contactsScroll: {
    paddingHorizontal: Spacing.lg,
  },
  contactItem: {
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  contactAvatar: {
    width: 64,
    height: 64,
    borderRadius: Radius.pill,
  },
  contactName: {
    
    color: Colors.textPrimary,
    marginTop: Spacing.xs,
  },
  quickActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
  },
  quickAction: {
    width: '47%',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    ...Shadows.card,
  },
  quickActionIcon: {
    width: 56,
    height: 56,
    borderRadius: Radius.lg,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  quickActionLabel: {
    
    color: Colors.textPrimary,
    marginTop: Spacing.sm,
  },
  resultsContainer: {
    flex: 1,
    paddingHorizontal: Spacing.lg,
  },
});
