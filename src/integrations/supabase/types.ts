export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      chats: {
        Row: {
          created_at: string | null
          group_id: string | null
          id: string
          message: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          group_id?: string | null
          id?: string
          message?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          group_id?: string | null
          id?: string
          message?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chats_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chats_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      checkins: {
        Row: {
          completed_habit_ids: string[] | null
          created_at: string | null
          day_number: number | null
          group_id: string | null
          id: string
          note: string | null
          photo_path: string | null
          points_earned: number | null
          user_id: string | null
        }
        Insert: {
          completed_habit_ids?: string[] | null
          created_at?: string | null
          day_number?: number | null
          group_id?: string | null
          id?: string
          note?: string | null
          photo_path?: string | null
          points_earned?: number | null
          user_id?: string | null
        }
        Update: {
          completed_habit_ids?: string[] | null
          created_at?: string | null
          day_number?: number | null
          group_id?: string | null
          id?: string
          note?: string | null
          photo_path?: string | null
          points_earned?: number | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "checkins_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "checkins_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      group_members: {
        Row: {
          current_streak: number | null
          group_id: string | null
          id: string
          is_out: boolean | null
          joined_at: string | null
          lives_remaining: number | null
          restart_count: number | null
          role: string | null
          skips_used: number | null
          total_points: number | null
          user_id: string | null
        }
        Insert: {
          current_streak?: number | null
          group_id?: string | null
          id?: string
          is_out?: boolean | null
          joined_at?: string | null
          lives_remaining?: number | null
          restart_count?: number | null
          role?: string | null
          skips_used?: number | null
          total_points?: number | null
          user_id?: string | null
        }
        Update: {
          current_streak?: number | null
          group_id?: string | null
          id?: string
          is_out?: boolean | null
          joined_at?: string | null
          lives_remaining?: number | null
          restart_count?: number | null
          role?: string | null
          skips_used?: number | null
          total_points?: number | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "group_members_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      groups: {
        Row: {
          code: string
          created_at: string | null
          created_by: string | null
          duration_days: number | null
          id: string
          is_active: boolean | null
          mode: string | null
          name: string
          start_date: string | null
        }
        Insert: {
          code: string
          created_at?: string | null
          created_by?: string | null
          duration_days?: number | null
          id?: string
          is_active?: boolean | null
          mode?: string | null
          name: string
          start_date?: string | null
        }
        Update: {
          code?: string
          created_at?: string | null
          created_by?: string | null
          duration_days?: number | null
          id?: string
          is_active?: boolean | null
          mode?: string | null
          name?: string
          start_date?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "groups_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      habits: {
        Row: {
          category: string | null
          default_set: string | null
          description: string | null
          frequency: string | null
          id: string
          points: number | null
          slug: string | null
          title: string | null
        }
        Insert: {
          category?: string | null
          default_set?: string | null
          description?: string | null
          frequency?: string | null
          id?: string
          points?: number | null
          slug?: string | null
          title?: string | null
        }
        Update: {
          category?: string | null
          default_set?: string | null
          description?: string | null
          frequency?: string | null
          id?: string
          points?: number | null
          slug?: string | null
          title?: string | null
        }
        Relationships: []
      }
      payments: {
        Row: {
          amount_cents: number | null
          created_at: string | null
          currency: string | null
          id: string
          stripe_payment_id: string | null
          type: string | null
          user_id: string | null
        }
        Insert: {
          amount_cents?: number | null
          created_at?: string | null
          currency?: string | null
          id?: string
          stripe_payment_id?: string | null
          type?: string | null
          user_id?: string | null
        }
        Update: {
          amount_cents?: number | null
          created_at?: string | null
          currency?: string | null
          id?: string
          stripe_payment_id?: string | null
          type?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string | null
          display_name: string | null
          email: string | null
          full_name: string | null
          id: string
          max_groups: number | null
          subscription_status: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          display_name?: string | null
          email?: string | null
          full_name?: string | null
          id: string
          max_groups?: number | null
          subscription_status?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          display_name?: string | null
          email?: string | null
          full_name?: string | null
          id?: string
          max_groups?: number | null
          subscription_status?: string | null
        }
        Relationships: []
      }
      sz_checkins: {
        Row: {
          completed_habit_ids: string[] | null
          created_at: string | null
          day_number: number
          id: string
          note: string | null
          photo_url: string | null
          points_earned: number | null
          streak_id: string
          user_id: string
        }
        Insert: {
          completed_habit_ids?: string[] | null
          created_at?: string | null
          day_number: number
          id?: string
          note?: string | null
          photo_url?: string | null
          points_earned?: number | null
          streak_id: string
          user_id: string
        }
        Update: {
          completed_habit_ids?: string[] | null
          created_at?: string | null
          day_number?: number
          id?: string
          note?: string | null
          photo_url?: string | null
          points_earned?: number | null
          streak_id?: string
          user_id?: string
        }
        Relationships: []
      }
      sz_habits: {
        Row: {
          category: string | null
          created_at: string | null
          description: string | null
          frequency: string | null
          id: string
          points: number | null
          template_set: string | null
          title: string
        }
        Insert: {
          category?: string | null
          created_at?: string | null
          description?: string | null
          frequency?: string | null
          id?: string
          points?: number | null
          template_set?: string | null
          title: string
        }
        Update: {
          category?: string | null
          created_at?: string | null
          description?: string | null
          frequency?: string | null
          id?: string
          points?: number | null
          template_set?: string | null
          title?: string
        }
        Relationships: []
      }
      sz_posts: {
        Row: {
          caption: string | null
          created_at: string | null
          day_number: number
          id: string
          photo_url: string
          streak_id: string
          user_id: string
        }
        Insert: {
          caption?: string | null
          created_at?: string | null
          day_number: number
          id?: string
          photo_url: string
          streak_id: string
          user_id: string
        }
        Update: {
          caption?: string | null
          created_at?: string | null
          day_number?: number
          id?: string
          photo_url?: string
          streak_id?: string
          user_id?: string
        }
        Relationships: []
      }
      sz_streak_members: {
        Row: {
          bonus_points: number | null
          current_streak: number | null
          hearts_available: number | null
          hearts_earned: number | null
          hearts_used: number | null
          id: string
          is_out: boolean | null
          joined_at: string | null
          left_at: string | null
          lives_remaining: number | null
          role: string | null
          status: string | null
          streak_id: string
          total_points: number | null
          user_id: string
        }
        Insert: {
          bonus_points?: number | null
          current_streak?: number | null
          hearts_available?: number | null
          hearts_earned?: number | null
          hearts_used?: number | null
          id?: string
          is_out?: boolean | null
          joined_at?: string | null
          left_at?: string | null
          lives_remaining?: number | null
          role?: string | null
          status?: string | null
          streak_id: string
          total_points?: number | null
          user_id: string
        }
        Update: {
          bonus_points?: number | null
          current_streak?: number | null
          hearts_available?: number | null
          hearts_earned?: number | null
          hearts_used?: number | null
          id?: string
          is_out?: boolean | null
          joined_at?: string | null
          left_at?: string | null
          lives_remaining?: number | null
          role?: string | null
          status?: string | null
          streak_id?: string
          total_points?: number | null
          user_id?: string
        }
        Relationships: []
      }
      sz_streaks: {
        Row: {
          code: string
          created_at: string | null
          created_by: string
          duration_days: number
          heart_sharing_enabled: boolean | null
          hearts_per_100_points: number | null
          id: string
          is_active: boolean | null
          mode: string
          name: string
          points_to_hearts_enabled: boolean | null
          start_date: string
        }
        Insert: {
          code: string
          created_at?: string | null
          created_by: string
          duration_days?: number
          heart_sharing_enabled?: boolean | null
          hearts_per_100_points?: number | null
          id?: string
          is_active?: boolean | null
          mode: string
          name: string
          points_to_hearts_enabled?: boolean | null
          start_date: string
        }
        Update: {
          code?: string
          created_at?: string | null
          created_by?: string
          duration_days?: number
          heart_sharing_enabled?: boolean | null
          hearts_per_100_points?: number | null
          id?: string
          is_active?: boolean | null
          mode?: string
          name?: string
          points_to_hearts_enabled?: boolean | null
          start_date?: string
        }
        Relationships: []
      }
      sz_user_habits: {
        Row: {
          created_at: string | null
          habit_id: string
          id: string
          streak_id: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          habit_id: string
          id?: string
          streak_id: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          habit_id?: string
          id?: string
          streak_id?: string
          user_id?: string
        }
        Relationships: []
      }
      sz_hearts_transactions: {
        Row: {
          created_at: string | null
          day_number: number
          from_user_id: string
          hearts_amount: number
          id: string
          note: string | null
          streak_id: string
          to_user_id: string
          transaction_type: string
        }
        Insert: {
          created_at?: string | null
          day_number: number
          from_user_id: string
          hearts_amount?: number
          id?: string
          note?: string | null
          streak_id: string
          to_user_id: string
          transaction_type?: string
        }
        Update: {
          created_at?: string | null
          day_number?: number
          from_user_id?: string
          hearts_amount?: number
          id?: string
          note?: string | null
          streak_id?: string
          to_user_id?: string
          transaction_type?: string
        }
        Relationships: []
      }
      sz_user_roles: {
        Row: {
          granted_at: string | null
          granted_by: string | null
          id: string
          is_active: boolean | null
          role: string
          user_id: string
        }
        Insert: {
          granted_at?: string | null
          granted_by?: string | null
          id?: string
          is_active?: boolean | null
          role?: string
          user_id: string
        }
        Update: {
          granted_at?: string | null
          granted_by?: string | null
          id?: string
          is_active?: boolean | null
          role?: string
          user_id?: string
        }
        Relationships: []
      }
      user_habits: {
        Row: {
          created_at: string | null
          group_id: string | null
          habit_id: string | null
          id: string
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          group_id?: string | null
          habit_id?: string | null
          id?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          group_id?: string | null
          habit_id?: string | null
          id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_habits_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_habits_habit_id_fkey"
            columns: ["habit_id"]
            isOneToOne: false
            referencedRelation: "habits"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_habits_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      add_habit_if_absent: {
        Args: {
          p_category: string
          p_default_set?: string
          p_description: string
          p_frequency?: string
          p_points: number
          p_slug: string
          p_title: string
        }
        Returns: string
      }
      assign_mode_template_to_group: {
        Args: { p_group_id: string; p_mode: string }
        Returns: boolean
      }
      assign_mode_template_to_user: {
        Args: { p_group_id: string; p_user_id: string }
        Returns: boolean
      }
      checkin: {
        Args: {
          p_completed_habit_ids: string[]
          p_day_number: number
          p_group_id: string
          p_note: string
          p_photo_path: string
        }
        Returns: {
          current_streak: number
          points_earned: number
          total_daily_points: number
        }[]
      }
      checkin_multi: {
        Args: {
          p_completed_habit_ids: string[]
          p_note?: string
          p_photo_path?: string
          p_primary_group: string
        }
        Returns: Json
      }
      create_group: {
        Args: {
          p_duration_days: number
          p_mode: string
          p_name: string
          p_start_date: string
        }
        Returns: {
          group_id: string
          join_code: string
        }[]
      }
      delete_group: {
        Args: { p_group_id: string }
        Returns: undefined
      }
      generate_group_code: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      get_daily_progress: {
        Args: { p_day_number: number; p_group_id: string; p_user_id: string }
        Returns: {
          checkin_count: number
          completed_habits: string[]
          last_checkin_at: string
          total_points: number
        }[]
      }
      get_group_checkins: {
        Args: { p_group_id: string; p_limit?: number }
        Returns: {
          avatar_url: string
          created_at: string
          day_number: number
          display_name: string
          id: string
          note: string
          photo_path: string
          points_earned: number
          user_id: string
        }[]
      }
      get_group_details: {
        Args: { p_group_id: string; p_user_id: string }
        Returns: {
          code: string
          duration_days: number
          group_id: string
          is_active: boolean
          mode: string
          name: string
          start_date: string
          user_current_streak: number
          user_joined_at: string
          user_lives_remaining: number
          user_role: string
          user_total_points: number
        }[]
      }
      get_group_leaderboard: {
        Args: { p_group_id: string }
        Returns: {
          avatar_url: string
          current_streak: number
          display_name: string
          is_out: boolean
          lives_remaining: number
          rank: number
          role: string
          total_points: number
          user_id: string
        }[]
      }
      get_group_members: {
        Args: { p_group_id: string }
        Returns: {
          avatar_url: string
          current_streak: number
          display_name: string
          id: string
          is_out: boolean
          joined_at: string
          lives_remaining: number
          restart_count: number
          role: string
          total_points: number
          user_id: string
        }[]
      }
      get_group_members_details: {
        Args: { p_group_id: string }
        Returns: {
          avatar_url: string
          current_streak: number
          display_name: string
          is_out: boolean
          lives_remaining: number
          role: string
          total_points: number
          user_id: string
        }[]
      }
      get_group_members_for_user: {
        Args: { p_group_id: string }
        Returns: {
          avatar_url: string
          current_streak: number
          display_name: string
          is_out: boolean
          joined_at: string
          lives_remaining: number
          role: string
          total_points: number
          user_id: string
        }[]
      }
      get_mode_template_habits: {
        Args: { p_mode: string }
        Returns: {
          category: string
          description: string
          frequency: string
          habit_id: string
          is_template: boolean
          points: number
          title: string
        }[]
      }
      get_user_checkin_history: {
        Args: { p_days_back?: number; p_group_id: string; p_user_id: string }
        Returns: {
          checkin_count: number
          checkin_date: string
          logged: boolean
          total_points: number
        }[]
      }
      get_user_checkins: {
        Args: { p_group_id: string; p_limit?: number; p_user_id: string }
        Returns: {
          created_at: string
          day_number: number
          id: string
          note: string
          photo_path: string
          points_earned: number
        }[]
      }
      get_user_groups: {
        Args: Record<PropertyKey, never>
        Returns: {
          code: string
          current_streak: number
          duration_days: number
          group_id: string
          is_active: boolean
          lives_remaining: number
          mode: string
          name: string
          role: string
          start_date: string
          total_points: number
        }[]
      }
      get_user_selected_habits: {
        Args: { p_group_id: string; p_user_id: string }
        Returns: {
          category: string
          default_set: string
          description: string
          frequency: string
          habit_id: string
          points: number
          title: string
        }[]
      }
      join_group: {
        Args: { p_code: string }
        Returns: string
      }
      sz_can_modify_habits: {
        Args: { p_streak_id: string; p_user_id: string }
        Returns: boolean
      }
      sz_checkin: {
        Args: {
          p_completed_habit_ids: string[]
          p_day_number: number
          p_note?: string
          p_photo_url?: string
          p_streak_id: string
        }
        Returns: {
          current_streak: number
          points_earned: number
          total_points: number
        }[]
      }
      sz_create_streak: {
        Args: {
          p_duration_days?: number
          p_mode: string
          p_name: string
          p_start_date: string
        }
        Returns: {
          streak_code: string
          streak_id: string
        }[]
      }
      sz_generate_streak_code: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      sz_join_streak: {
        Args: { p_code: string }
        Returns: string
      }
      sz_leave_streak: {
        Args: { p_streak_id: string }
        Returns: undefined
      }
      sz_recalculate_user_points: {
        Args: { p_streak_id: string; p_user_id: string }
        Returns: undefined
      }
      sz_save_user_habits: {
        Args: { p_habit_ids: string[]; p_streak_id: string }
        Returns: undefined
      }
      use_life: {
        Args: {
          p_completed_habit_ids: string[]
          p_day_number: number
          p_group_id: string
          p_user_id: string
        }
        Returns: undefined
      }
      user_is_streak_member: {
        Args: { p_streak_id: string }
        Returns: boolean
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
