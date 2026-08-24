import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import LoginScreen from '../screens/LoginScreen';
import RegisterScreen from '../screens/RegisterScreen';
import ForgotPasswordScreen from '../screens/ForgotPasswordScreen';
import SetPinScreen from '../screens/SetPinScreen';
import OtpVerificationScreen from '../screens/OtpVerificationScreen';
import ForgotPinScreen from '../screens/ForgotPinScreen';
import HomeScreen from '../screens/HomeScreen';
import HistoryScreen from '../screens/HistoryScreen';
import ChooseRecipientScreen from '../screens/ChooseRecipientScreen';
import EnterAmountScreen from '../screens/EnterAmountScreen';
import ConfirmTransferScreen from '../screens/ConfirmTransferScreen';
import TransferResultScreen from '../screens/TransferResultScreen';
import TransferConfirmScreen from '../screens/TransferConfirmScreen';
import ScanQRScreen from '../screens/ScanQRScreen';
import QRMyScreen from '../screens/QRMyScreen';
import TransactionDetailScreen from '../screens/TransactionDetailScreen';
import NotificationsScreen from '../screens/NotificationsScreen';
import ProfileScreen from '../screens/ProfileScreen';
import SecuritySettingsScreen from '../screens/SecuritySettingsScreen';
import DeviceManagementScreen from '../screens/DeviceManagementScreen';
import WithdrawScreen from '../screens/WithdrawScreen';
import DepositScreen from '../screens/DepositScreen';
import PaymentMethodsScreen from '../screens/PaymentMethodsScreen';
import BankCardsScreen from '../screens/BankCardsScreen';
import BillPaymentScreen from '../screens/BillPaymentScreen';
import BillInputScreen from '../screens/BillInputScreen';
import RequestTransferScreen from '../screens/RequestTransferScreen';
import PromotionsScreen from '../screens/PromotionsScreen';
import HelpCenterScreen from '../screens/HelpCenterScreen';
import SearchScreen from '../screens/SearchScreen';
import MainTabs from './MainTabs';

const Stack = createStackNavigator();

export default function AppNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerShown: false,
        }}
        initialRouteName="Login"
      >
        {/* Auth screens */}
        <Stack.Screen name="Login" component={LoginScreen} />
        <Stack.Screen name="Register" component={RegisterScreen} />
        <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
        <Stack.Screen name="SetPin" component={SetPinScreen} />
        <Stack.Screen name="OtpVerification" component={OtpVerificationScreen} />
        <Stack.Screen name="ForgotPin" component={ForgotPinScreen} />

        {/* Main tabs */}
        <Stack.Screen name="MainTabs" component={MainTabs} />

        {/* Transfer flow */}
        <Stack.Screen name="Deposit" component={DepositScreen} />
        <Stack.Screen name="Withdraw" component={WithdrawScreen} />
        <Stack.Screen name="Transfer" component={ChooseRecipientScreen} />
        <Stack.Screen name="EnterAmount" component={EnterAmountScreen} />
        <Stack.Screen name="ConfirmTransfer" component={ConfirmTransferScreen} />
        <Stack.Screen name="TransferConfirm" component={TransferConfirmScreen} />
        <Stack.Screen name="TransferResult" component={TransferResultScreen} />
        <Stack.Screen name="ScanQR" component={ScanQRScreen} />

        {/* QR */}
        <Stack.Screen name="MyQR" component={QRMyScreen} />

        {/* Transaction detail */}
        <Stack.Screen name="TransactionDetail" component={TransactionDetailScreen} />

        {/* Notifications */}
        <Stack.Screen name="Notifications" component={NotificationsScreen} />

        {/* Profile & Settings */}
        <Stack.Screen name="EditProfile" component={ProfileScreen} />
        <Stack.Screen name="SecuritySettings" component={SecuritySettingsScreen} />
        <Stack.Screen name="DeviceManagement" component={DeviceManagementScreen} />
        <Stack.Screen name="PaymentMethods" component={PaymentMethodsScreen} />
        <Stack.Screen name="BankCardManagement" component={BankCardsScreen} />

        {/* Bills */}
        <Stack.Screen name="BillPayment" component={BillPaymentScreen} />
        <Stack.Screen name="BillInput" component={BillInputScreen} />

        {/* Request transfer */}
        <Stack.Screen name="RequestTransfer" component={RequestTransferScreen} />

        {/* Promotions */}
        <Stack.Screen name="Promotions" component={PromotionsScreen} />

        {/* Help */}
        <Stack.Screen name="HelpCenter" component={HelpCenterScreen} />
        <Stack.Screen name="LiveChat" component={HelpCenterScreen} />

        {/* Search */}
        <Stack.Screen name="Search" component={SearchScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
