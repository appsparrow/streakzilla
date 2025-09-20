import React from 'react';
import { View, Text } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RouteProp } from '@react-navigation/native';
import { RootStackParamList } from '../App';

type StreakDashboardScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'StreakDashboard'>;
type StreakDashboardScreenRouteProp = RouteProp<RootStackParamList, 'StreakDashboard'>;

interface Props {
  navigation: StreakDashboardScreenNavigationProp;
  route: StreakDashboardScreenRouteProp;
}

export default function StreakDashboardScreen({ navigation, route }: Props) {
  const { streakId } = route.params;

  return (
    <View className="flex-1 justify-center items-center bg-gray-50">
      <Text className="text-2xl font-bold text-gray-900 mb-4">Streak Dashboard</Text>
      <Text className="text-gray-600">Streak ID: {streakId}</Text>
      <Text className="text-gray-600">Coming soon...</Text>
    </View>
  );
}
