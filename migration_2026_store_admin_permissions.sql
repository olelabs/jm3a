-- Jma3a Store — Phase 2A foundation, part 9: new admin_permissions rows
-- for Store administration. Inserted UNASSIGNED to every role — no
-- existing admin gains any new access from this migration by itself; a
-- super-admin must explicitly assign these to a role afterward via the
-- existing role-management UI/RPCs, per the task's explicit instruction.
--
-- VERIFIED AGAINST LIVE PRODUCTION (via Supabase SQL Editor, superseding
-- an earlier draft of this file that could only infer the column list
-- from application code, not a real CREATE TABLE): admin_permissions has
-- columns (id, code, category, description, created_at), and `code` is
-- UNIQUE. This migration now uses ON CONFLICT (code) DO NOTHING —
-- correct and safe now that the unique constraint backing it is
-- confirmed, and simpler/more atomic than the previous draft's
-- WHERE NOT EXISTS guards (kept in the earlier draft only because the
-- constraint wasn't yet confirmed). `id`/`created_at` are left to their
-- column defaults, matching every other table in this codebase's own
-- convention — not verified individually, but not a meaningful risk
-- given how uniform that convention is everywhere else.
--
-- Existing permission rows (their actual current contents) were still
-- not read as part of this verification — only the table's structure
-- and the fact that none of the five new codes below currently exist
-- (confirmed against the repositories). ON CONFLICT (code) DO NOTHING
-- makes this safe regardless: if any of these five codes somehow
-- already existed for an unrelated reason, this migration would skip
-- that row untouched rather than overwrite it.
--
-- `category` uses a new value, 'store', not present in
-- jma3a_admin/lib/shared/utils/permission_categories.dart's existing
-- switch (dashboard/users/finance/packs/reports/rooms/games/statistics/
-- settings/notifications/creators/account_deletions/subscriptions/
-- admin_users/audit_logs). That switch's `_ => category` fallback
-- renders any unrecognized category as its raw string, so this degrades
-- gracefully (permissions still work, just displayed as literal "store"
-- instead of a localized label) — adding the proper localized label is
-- deferred to the later jma3a_admin UI phase, per this task's explicit
-- instruction not to touch Flutter admin code yet.
--
-- Idempotent (ON CONFLICT DO NOTHING), safe to re-run. NOT applied
-- automatically — for manual application only. Not executed against
-- production this session.

INSERT INTO public.admin_permissions (code, category, description) VALUES
  ('store_products.manage', 'store', 'Create, edit, and enable/disable Jma3a Store products (packs, Premium, Premium Plus).'),
  ('store_payment_methods.manage', 'store', 'Create, edit, and enable/disable Jma3a Store local payment methods.'),
  ('store_orders.view', 'store', 'View Jma3a Store orders, including payment proof.'),
  ('store_orders.approve', 'store', 'Approve a Jma3a Store order and grant the resulting Jma3a entitlement.'),
  ('store_orders.reject', 'store', 'Reject a Jma3a Store order.')
ON CONFLICT (code) DO NOTHING;

-- Deliberately no INSERT into admin_role_permissions here — these five
-- permissions are intentionally left unassigned to every role. Assign
-- them to whichever role(s) should administer the Store via the
-- existing role-management UI once this phase is reviewed.
