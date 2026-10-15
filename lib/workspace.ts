import {db} from './supabase';import {redirect} from 'next/navigation';
export async function workspace(){const supabase=await db();const {data:{user}}=await supabase.auth.getUser();if(!user)redirect('/login');const {data:profile}=await supabase.from('profiles').select('role,full_name').eq('id',user.id).single();return {supabase,user,role:profile?.role||'client',name:profile?.full_name||user.email||'Member'}}
export const statusLabel:Record<string,string>={to_edit:'To Edit',editing:'In Editing',review:'In Review',changes:'Changes Requested',approved:'Approved',delivered:'Delivered'};
