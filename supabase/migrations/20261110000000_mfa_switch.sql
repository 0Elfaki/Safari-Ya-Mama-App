-- Two-step sign-in (TOTP, aal2) as a switch. The owner asked (10 Nov 2026) for quick access with
-- email and password only, for now, with two-step sign-in "on hold" to switch back on later.
--   security_settings.require_mfa = false → mfa_ok() is true for every signed-in session, so every
--   rule that needs MFA (platform admins, website team, admins at a facility) accepts a password
--   sign-in. Set it back to true (System health › Security, super admin) to require the code again.
-- Every change of the switch is written to audit_log.

create table if not exists public.security_settings (
  id integer primary key default 1 check (id = 1),
  require_mfa boolean not null default true,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.security_settings enable row level security; -- read through the functions below
revoke all on public.security_settings from anon, authenticated;
insert into public.security_settings (id, require_mfa) values (1, false)
on conflict (id) do update set require_mfa = false, updated_at = now();

create or replace function public.mfa_required()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select require_mfa from security_settings where id = 1), true)
$$;

create or replace function public.mfa_ok()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt() ->> 'aal', '') = 'aal2' or not public.mfa_required()
$$;

-- Super admin only. Turning it on while signed in without a code is allowed: the next sign-in asks for it.
create or replace function public.set_require_mfa(p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_super_admin() then
    raise exception 'Only the super admin can change this.' using errcode = '42501';
  end if;
  update security_settings set require_mfa = p_on, updated_by = auth.uid(), updated_at = now() where id = 1;
  insert into audit_log (actor_id, action, details) values (auth.uid(), 'security_mfa', jsonb_build_object('require_mfa', p_on));
end $$;

revoke all on function public.mfa_required() from public;
grant execute on function public.mfa_required() to anon, authenticated;
revoke all on function public.set_require_mfa(boolean) from public, anon;
grant execute on function public.set_require_mfa(boolean) to authenticated;
