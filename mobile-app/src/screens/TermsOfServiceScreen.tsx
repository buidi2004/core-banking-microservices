import React, { useState, useRef } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  TextInput,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { WalletApi } from '../services/api';
import { ActivityIndicator } from 'react-native';

const { width } = Dimensions.get('window');

const SECTIONS = [
  { id: 'c1', title: 'I. Quy định chung' },
  { id: 'c2', title: 'II. Đăng ký & eKYC' },
  { id: 'c3', title: 'III. Quyền KH' },
  { id: 'c4', title: 'IV. Trách nhiệm MB' },
  { id: 'c5', title: 'V. Bảo mật & NĐ 13' },
  { id: 'c6', title: 'VI. Biểu phí & Khiếu nại' },
];

export default function TermsOfServiceScreen({ navigation }: { navigation: any }) {
  const [selectedSection, setSelectedSection] = useState('c1');
  const [searchQuery, setSearchQuery] = useState('');
  const [terms, setTerms] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const scrollViewRef = useRef<ScrollView>(null);

  React.useEffect(() => {
    const fetchTerms = async () => {
      try {
        const res = await WalletApi.getTerms();
        setTerms(res.data);
      } catch (e) {
        console.error('Failed to get terms', e);
      } finally {
        setIsLoading(false);
      }
    };
    fetchTerms();
  }, []);

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* 1. TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Điều khoản sử dụng dịch vụ</AppText>

        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Home')}
        >
          <Ionicons name="home-outline" size={22} color="#700F43" />
        </TouchableOpacity>
      </View>

      {/* 2. SEARCH BAR */}
      <View style={styles.searchBarWrapper}>
        <Ionicons name="search-outline" size={20} color="#94A3B8" />
        <TextInput
          style={styles.searchInput}
          placeholder="Tìm kiếm nội dung điều khoản..."
          placeholderTextColor="#94A3B8"
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity onPress={() => setSearchQuery('')}>
            <Ionicons name="close-circle" size={18} color="#94A3B8" />
          </TouchableOpacity>
        )}
      </View>

      {/* 3. SECTION CHIPS CAROUSEL */}
      <View style={styles.chipsContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chipsScroll}>
          {SECTIONS.map((sec) => {
            const isSelected = selectedSection === sec.id;
            return (
              <TouchableOpacity
                key={sec.id}
                style={[styles.chipPill, isSelected && styles.chipPillActive]}
                activeOpacity={0.8}
                onPress={() => setSelectedSection(sec.id)}
              >
                <AppText style={[styles.chipText, isSelected && styles.chipTextActive]}>
                  {sec.title}
                </AppText>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* 4. MAIN LEGAL DOCUMENT CONTENT */}
      <ScrollView
        ref={scrollViewRef}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Document Header Banner */}
        {isLoading ? (
          <ActivityIndicator size="large" color="#D2519D" style={{ marginTop: 40 }} />
        ) : (
          <>
            <View style={styles.docHeaderBanner}>
              <View style={styles.bankBadgeHeader}>
                <AppText style={{ color: '#E11D48', fontSize: 18, fontWeight: '900' }}>★</AppText>
                <AppText style={styles.mbTextLogo}>SenBank</AppText>
              </View>
              <AppText style={styles.docTitle}>
                {terms?.title || 'ĐIỀU KHOẢN VÀ ĐIỀU KIỆN SỬ DỤNG DỊCH VỤ NGÂN HÀNG ĐIỆN TỬ'}
              </AppText>
              <AppText style={styles.docSubMeta}>
                Ban hành theo Quyết định của Tổng Giám đốc Ngân hàng SenBank{'\n'}
                Cập nhật phiên bản: {terms?.version || '2026.08'} | Hiệu lực thi hành trên toàn quốc
              </AppText>
            </View>

            {/* CHƯƠNG I */}
            <View style={styles.legalSection}>
              <AppText style={styles.sectionHeaderTitle}>CHƯƠNG I: QUY ĐỊNH CHUNG</AppText>

              <AppText style={styles.articleTitle}>Nội dung</AppText>
              <AppText style={styles.paragraph}>
                {terms?.content || 'Đang tải nội dung...'}
              </AppText>
            </View>
          </>
        )}
      </ScrollView>

      {/* 5. FOOTER ACCEPT BUTTON */}
      <View style={styles.bottomFooter}>
        <TouchableOpacity
          style={styles.acceptBtn}
          activeOpacity={0.9}
          onPress={() => navigation.goBack()}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <Ionicons name="shield-checkmark" size={20} color="#FFFFFF" style={{ marginRight: 8 }} />
          <AppText style={styles.acceptBtnText}>Tôi đã hiểu và đồng ý</AppText>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  headerBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 17.5,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.3,
  },
  searchBarWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginTop: 12,
    marginBottom: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: '#0F172A',
    fontWeight: '600',
  },
  chipsContainer: {
    paddingVertical: 6,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  chipsScroll: {
    paddingHorizontal: 16,
    gap: 8,
  },
  chipPill: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 16,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  chipPillActive: {
    backgroundColor: '#FDF2F8',
    borderColor: '#D2519D',
  },
  chipText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
  },
  chipTextActive: {
    color: '#700F43',
    fontWeight: '800',
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 110,
  },
  docHeaderBanner: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#FCE7F3',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 16,
    alignItems: 'center',
  },
  bankBadgeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 10,
  },
  mbTextLogo: {
    fontSize: 20,
    fontWeight: '900',
    color: '#700F43',
  },
  docTitle: {
    fontSize: 15.5,
    fontWeight: '900',
    color: '#0F172A',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 8,
  },
  docSubMeta: {
    fontSize: 12,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 17,
  },
  legalSection: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 16,
  },
  sectionHeaderTitle: {
    fontSize: 14.5,
    fontWeight: '900',
    color: '#700F43',
    marginBottom: 12,
    letterSpacing: 0.2,
  },
  articleTitle: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#0F172A',
    marginTop: 8,
    marginBottom: 6,
  },
  paragraph: {
    fontSize: 13,
    color: '#334155',
    lineHeight: 20,
    fontWeight: '500',
  },
  boldText: {
    fontWeight: '800',
    color: '#0F172A',
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 24,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  acceptBtn: {
    width: '100%',
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  acceptBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
