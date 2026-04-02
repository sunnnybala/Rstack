#!/usr/bin/env bash
# Supabase project config for rstack telemetry
#
# These are PUBLIC keys — safe to commit (like Firebase public config).
# RLS enforces access control. All reads and writes go through edge
# functions (which use SUPABASE_SERVICE_ROLE_KEY server-side).
#
# Replace these placeholders after creating your Supabase project.

RSTACK_SUPABASE_URL=""
RSTACK_SUPABASE_ANON_KEY=""
