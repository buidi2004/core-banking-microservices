import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { View, StyleSheet, TouchableOpacity, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors, Typography } from '../theme';
import HomeScreen from '../screens/HomeScreen';
import HistoryScreen from '../screens/HistoryScreen';
import ScanQRScreen from '../screens/ScanQRScreen';
import QRMyScreen from '../screens/QRMyScreen';
import NotificationsScreen from '../screens/NotificationsScreen';
import PromotionsScreen from '../screens/PromotionsScreen';
import ProfileScreen from '../screens/ProfileScreen';

const Tab = createBottomTabNavigator();

export default function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: true,
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: Colors.white,
        tabBarInactiveTintColor: 'rgba(255, 255, 255, 0.75)',
        tabBarLabelStyle: styles.tabBarLabel,
        tabBarBackground: () => (
          <View style={styles.tabBarBackgroundWrapper}>
            <BlurView intensity={35} tint="dark" style={StyleSheet.absoluteFill} />
            <LinearGradient
              colors={['rgba(210, 81, 157, 0.90)', 'rgba(112, 15, 67, 0.95)']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
          </View>
        ),
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          title: 'Trang chủ',
          tabBarIcon: ({ focused }) => (
            <Ionicons
              name={focused ? "home" : "home-outline"}
              size={22}
              color={focused ? '#FFFFFF' : 'rgba(255,255,255,0.75)'}
            />
          ),
        }}
      />
      <Tab.Screen
        name="Card"
        component={HistoryScreen}
        options={{
          title: 'Thẻ',
          tabBarIcon: ({ color }) => (
            <MaterialCommunityIcons name="credit-card-multiple-outline" size={22} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="QR"
        component={ScanQRScreen}
        options={{
          title: ' ',
          tabBarButton: (props: any) => (
            <TouchableOpacity
              style={styles.qrTabButton}
              onPress={props.onPress}
              activeOpacity={0.85}
            >
              <View style={styles.qrInner}>
                <MaterialCommunityIcons name="qrcode-scan" size={28} color="#D2519D" />
              </View>
            </TouchableOpacity>
          ),
          tabBarIcon: () => null,
        }}
      />
      <Tab.Screen
        name="Gift"
        component={PromotionsScreen}
        options={{
          title: 'Ưu đãi',
          tabBarIcon: ({ color, focused }) => (
            <Ionicons
              name={focused ? "gift" : "gift-outline"}
              size={22}
              color={color}
            />
          ),
        }}
      />
      <Tab.Screen
        name="More"
        component={ProfileScreen}
        options={{
          title: 'Thêm',
          tabBarIcon: ({ color }) => (
            <MaterialCommunityIcons name="dots-grid" size={24} color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: 'transparent',
    borderTopWidth: 0,
    height: 72,
    borderRadius: 20,
    marginHorizontal: 16,
    position: 'absolute',
    bottom: Platform.OS === 'ios' ? 24 : 16,
    left: 0,
    right: 0,
    paddingBottom: 8,
    paddingTop: 8,
    borderWidth: 1.2,
    borderColor: 'rgba(255, 255, 255, 0.25)',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 12,
  },
  tabBarBackgroundWrapper: {
    borderRadius: 20,
    overflow: 'hidden',
    ...StyleSheet.absoluteFillObject,
  },
  tabBarLabel: {
    fontSize: 11,
    fontFamily: Typography.captionSm.fontFamily,
    fontWeight: '600',
    marginTop: 2,
    letterSpacing: 0.3,
  },
  qrTabButton: {
    top: 0,
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 4,
  },
  qrInner: {
    width: 50,
    height: 50,
    borderRadius: 15,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#FFFFFF',
  },
});