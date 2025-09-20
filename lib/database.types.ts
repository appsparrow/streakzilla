export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          first_name: string | null
          last_name: string | null
          display_name: string | null
          avatar_url: string | null
          phone: string | null
          subscription_status: string
          created_at: string
        }
        Insert: {
          id: string
          first_name?: string | null
          last_name?: string | null
          display_name?: string | null
          avatar_url?: string | null
          phone?: string | null
          subscription_status?: string
          created_at?: string
        }
        Update: {
          id?: string
          first_name?: string | null
          last_name?: string | null
          display_name?: string | null
          avatar_url?: string | null
          phone?: string | null
          subscription_status?: string
          created_at?: string
        }
      }
      streaks: {
        Row: {
          id: string
          name: string
          code: string
          created_by: string | null
          mode: string | null
          duration_days: number | null
          start_date: string | null
          status: string
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          code: string
          created_by?: string | null
          mode?: string | null
          duration_days?: number | null
          start_date?: string | null
          status?: string
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          code?: string
          created_by?: string | null
          mode?: string | null
          duration_days?: number | null
          start_date?: string | null
          status?: string
          created_at?: string
        }
      }
      streak_members: {
        Row: {
          id: string
          streak_id: string
          user_id: string
          role: string
          joined_at: string
          lives_remaining: number
          is_active: boolean
          restart_count: number
        }
        Insert: {
          id?: string
          streak_id: string
          user_id: string
          role?: string
          joined_at?: string
          lives_remaining?: number
          is_active?: boolean
          restart_count?: number
        }
        Update: {
          id?: string
          streak_id?: string
          user_id?: string
          role?: string
          joined_at?: string
          lives_remaining?: number
          is_active?: boolean
          restart_count?: number
        }
      }
      powers: {
        Row: {
          id: string
          slug: string | null
          title: string | null
          description: string | null
          category: string | null
          frequency: string | null
          default_set: string | null
          created_at: string
        }
        Insert: {
          id?: string
          slug?: string | null
          title?: string | null
          description?: string | null
          category?: string | null
          frequency?: string | null
          default_set?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          slug?: string | null
          title?: string | null
          description?: string | null
          category?: string | null
          frequency?: string | null
          default_set?: string | null
          created_at?: string
        }
      }
      member_powers: {
        Row: {
          id: string
          member_id: string
          power_id: string
          selected_at: string
        }
        Insert: {
          id?: string
          member_id: string
          power_id: string
          selected_at?: string
        }
        Update: {
          id?: string
          member_id?: string
          power_id?: string
          selected_at?: string
        }
      }
      checkins: {
        Row: {
          id: string
          member_id: string
          streak_id: string
          day_number: number | null
          completed_power_ids: string[] | null
          all_done: boolean
          photo_r2_key: string | null
          note: string | null
          created_at: string
        }
        Insert: {
          id?: string
          member_id: string
          streak_id: string
          day_number?: number | null
          completed_power_ids?: string[] | null
          all_done?: boolean
          photo_r2_key?: string | null
          note?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          member_id?: string
          streak_id?: string
          day_number?: number | null
          completed_power_ids?: string[] | null
          all_done?: boolean
          photo_r2_key?: string | null
          note?: string | null
          created_at?: string
        }
      }
      photos: {
        Row: {
          id: string
          member_id: string | null
          streak_id: string | null
          checkin_id: string | null
          r2_key: string | null
          created_at: string
        }
        Insert: {
          id?: string
          member_id?: string | null
          streak_id?: string | null
          checkin_id?: string | null
          r2_key?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          member_id?: string | null
          streak_id?: string | null
          checkin_id?: string | null
          r2_key?: string | null
          created_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      create_streak: {
        Args: {
          name: string
          mode: string
          start_date: string
          duration_days: number
        }
        Returns: {
          streak_id: string
          code: string
        }
      }
      join_streak: {
        Args: {
          code: string
        }
        Returns: {
          member_id: string
          streak_id: string
          day_offset: number
        }
      }
      leave_streak: {
        Args: {
          streak_id: string
        }
        Returns: void
      }
      end_streak: {
        Args: {
          streak_id: string
        }
        Returns: void
      }
      streak_dashboard: {
        Args: {
          streak_id: string
          member_id: string
        }
        Returns: Json
      }
      select_member_powers: {
        Args: {
          member_id: string
          power_ids: string[]
        }
        Returns: void
      }
      create_checkin: {
        Args: {
          member_id: string
          streak_id: string
          day_number: number
          completed_power_ids: string[]
          photo_r2_key?: string
          note?: string
        }
        Returns: {
          checkin_id: string
          all_done: boolean
        }
      }
      use_life_for_day: {
        Args: {
          member_id: string
          streak_id: string
          day_number: number
        }
        Returns: {
          success: boolean
          lives_remaining: number
        }
      }
      streak_leaderboard: {
        Args: {
          streak_id: string
        }
        Returns: Json
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
