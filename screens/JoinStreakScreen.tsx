import React from 'react';
import { View, Text } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '../App';

type JoinStreakScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'JoinStreak'>;

interface Props {
  navigation: JoinStreakScreenNavigationProp;
}

export default function JoinStreakScreen({ navigation }: Props) {
  return (
    <View className="flex-1 justify-center items-center bg-gray-50">
      <Text className="text-2xl font-bold text-gray-900 mb-4">Join Streak</Text>
      <Text className="text-gray-600">Coming soon...</Text>
    </View>
  );
}
