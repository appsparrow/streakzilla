import React from 'react';
import { View, ActivityIndicator, ViewStyle } from 'react-native';

interface LoadingSpinnerProps {
  size?: 'small' | 'large';
  color?: string;
  style?: ViewStyle;
}

export function LoadingSpinner({ 
  size = 'large', 
  color = '#f37d0a',
  style 
}: LoadingSpinnerProps) {
  return (
    <View 
      className="flex-1 justify-center items-center bg-gray-50"
      style={style}
    >
      <ActivityIndicator size={size} color={color} />
    </View>
  );
}
