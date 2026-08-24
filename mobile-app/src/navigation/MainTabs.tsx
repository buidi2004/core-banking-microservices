import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows } from '../theme';
import { Typography } from '../theme';
import HomeScreen from '../screens/HomeScreen';
import HistoryScreen from '../screens/HistoryScreen';
import QRMyScreen from '../screens/QRMyScreen';
import NotificationsScreen from '../screens/NotificationsScreen';
import ProfileScreen from '../screens/ProfileScreen';

const Tab = createBottomTabNavigator();

export default function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: true,
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textSecondary,
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          title: 'Trang chủ',
          tabBarIcon: ({ color, size }) => (
            <AppIcon name="home" size="sm" color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="History"
        component={HistoryScreen}
        options={{
          title: 'Lịch sử',
          tabBarIcon: ({ color, size }) => (
            <AppIcon name="history" size="sm" color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="QR"
        component={QRMyScreen}
        options={{
          title: 'QR',
          tabBarButton: (props: any) => (
            <View style={styles.qrTabWrapper}>
              <TouchableOpacity
                style={styles.qrTabButton}
                onPress={props.onPress}
                activeOpacity={0.8}
              >
                <LinearGradient
                  colors={[Colors.primary, Colors.heroGradMid]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.qrGradient}
                >
                  <AppIcon name="qr" size="lg" color={Colors.white} />
                </LinearGradient>
              </TouchableOpacity>
              <Text style={styles.qrTabLabel}>QR</Text>
            </View>
          ),
          tabBarIcon: () => null,
        }}
      />
      <Tab.Screen
        name="Notifications"
        component={NotificationsScreen}
        options={{
          title: 'Thông báo',
          tabBarIcon: ({ color, size }) => (
            <AppIcon name="notification" size="sm" color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Hồ sơ',
          tabBarIcon: ({ color, size }) => (
            <AppIcon name="profile" size="sm" color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    position: 'absolute',
    bottom: 12,
    left: 12,
    right: 12,
    height: 70,
    borderRadius: Radius.xxl,
    backgroundColor: Colors.glassSolid,
    ...Shadows.hero,
    borderTopWidth: 0,
    borderBottomWidth: 0,
    borderLeftWidth: 0,
    borderRightWidth: 0,
  },
  qrTabWrapper: {
    alignItems: 'center',
    justifyContent: 'flex-end',
    paddingBottom: 8,
  },
  qrTabButton: {
    width: 56,
    height: 56,
    borderRadius: Radius.pill,
    overflow: 'hidden',
    ...Shadows.hero,
    marginBottom: 4,
  },
  qrGradient: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  qrTabLabel: {
    fontSize: Typography.captionSm.fontSize,
    fontWeight: '600',
    color: Colors.primary,
  },
});