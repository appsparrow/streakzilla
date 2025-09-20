import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import Toast from 'react-native-toast-message';
import { AuthProvider, useAuth } from './context/AuthContext';
import { LoadingSpinner } from './components/ui/LoadingSpinner';

// Screens
import LoginScreen from './screens/LoginScreen';
import SignupScreen from './screens/SignupScreen';
import HomeScreen from './screens/HomeScreen';
import CreateStreakScreen from './screens/CreateStreakScreen';
import JoinStreakScreen from './screens/JoinStreakScreen';
import StreakDashboardScreen from './screens/StreakDashboardScreen';
import ProfileScreen from './screens/ProfileScreen';

export type RootStackParamList = {
  Login: undefined;
  Signup: undefined;
  Home: undefined;
  CreateStreak: undefined;
  JoinStreak: undefined;
  StreakDashboard: { streakId: string };
  Profile: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

function AuthStack() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Signup" component={SignupScreen} />
    </Stack.Navigator>
  );
}

function AppStack() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: {
          backgroundColor: '#ffffff',
        },
        headerTintColor: '#374151',
        headerTitleStyle: {
          fontWeight: '600',
        },
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen 
        name="Home" 
        component={HomeScreen}
        options={{ title: 'Streakzilla' }}
      />
      <Stack.Screen 
        name="CreateStreak" 
        component={CreateStreakScreen}
        options={{ title: 'Create Streak' }}
      />
      <Stack.Screen 
        name="JoinStreak" 
        component={JoinStreakScreen}
        options={{ title: 'Join Streak' }}
      />
      <Stack.Screen 
        name="StreakDashboard" 
        component={StreakDashboardScreen}
        options={{ title: 'Streak Dashboard' }}
      />
      <Stack.Screen 
        name="Profile" 
        component={ProfileScreen}
        options={{ title: 'Profile' }}
      />
    </Stack.Navigator>
  );
}

function Navigation() {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingSpinner />;
  }

  return (
    <NavigationContainer>
      {user ? <AppStack /> : <AuthStack />}
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Navigation />
      <StatusBar style="auto" />
      <Toast />
    </AuthProvider>
  );
}
