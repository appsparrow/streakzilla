-- Create sz_user_roles table for role management
CREATE TABLE IF NOT EXISTS public.sz_user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'moderator')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    UNIQUE(user_id, role)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sz_user_roles_user_id ON public.sz_user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_sz_user_roles_role ON public.sz_user_roles(role);
CREATE INDEX IF NOT EXISTS idx_sz_user_roles_active ON public.sz_user_roles(is_active);

-- Enable RLS (Row Level Security)
ALTER TABLE public.sz_user_roles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own roles" ON public.sz_user_roles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Super admins can view all roles" ON public.sz_user_roles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sz_user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'super_admin' 
            AND ur.is_active = true
        )
    );

CREATE POLICY "Super admins can manage all roles" ON public.sz_user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sz_user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'super_admin' 
            AND ur.is_active = true
        )
    );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_sz_user_roles_updated_at 
    BEFORE UPDATE ON public.sz_user_roles 
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();

-- Insert super admin role for streakzilla@gmail.com
-- First, let's find the user ID for streakzilla@gmail.com
INSERT INTO public.sz_user_roles (user_id, role, is_active, created_by)
SELECT 
    au.id as user_id,
    'super_admin' as role,
    true as is_active,
    au.id as created_by
FROM auth.users au
WHERE au.email = 'streakzilla@gmail.com'
ON CONFLICT (user_id, role) 
DO UPDATE SET 
    is_active = true,
    updated_at = NOW();

-- Verify the super admin was created
SELECT 
    ur.id,
    ur.user_id,
    au.email,
    ur.role,
    ur.is_active,
    ur.created_at
FROM public.sz_user_roles ur
JOIN auth.users au ON ur.user_id = au.id
WHERE ur.role = 'super_admin' AND ur.is_active = true;
