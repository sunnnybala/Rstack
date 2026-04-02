// rstack telemetry-ingest edge function
// Validates and inserts a batch of telemetry events.
// Called by bin/rstack-telemetry-sync.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface TelemetryEvent {
  v: number;
  ts: string;
  event_type: string;
  skill: string;
  session_id?: string;
  rstack_version: string;
  os: string;
  arch?: string;
  duration_s?: number;
  outcome: string;
  error_class?: string;
  error_message?: string;
  failed_step?: string;
  used_browse?: boolean;
  sessions?: number;
  installation_id?: string;
  // Research-specific fields
  compute_provider?: string;
  gpu_type?: string;
  venue?: string;
  pipeline_stage?: string;
}

const MAX_BATCH_SIZE = 100;
const MAX_PAYLOAD_BYTES = 50_000; // 50KB

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("POST required", { status: 405 });
  }

  try {
    // Check actual body size (don't trust Content-Length header)
    const rawBody = await req.text();
    if (rawBody.length > MAX_PAYLOAD_BYTES) {
      return new Response("Payload too large", { status: 413 });
    }

    const body = JSON.parse(rawBody);
    const events: TelemetryEvent[] = Array.isArray(body) ? body : [body];

    if (events.length > MAX_BATCH_SIZE) {
      return new Response(`Batch too large (max ${MAX_BATCH_SIZE})`, { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Validate and transform events
    const rows = [];
    const installationUpserts: Map<string, { version: string; os: string }> = new Map();

    for (const event of events) {
      // Required fields
      if (!event.ts || !event.rstack_version || !event.os || !event.outcome) {
        continue; // skip malformed
      }

      // Validate schema version
      if (event.v !== 1) continue;

      // Validate event_type
      const validTypes = ["skill_run", "upgrade_prompted", "upgrade_completed"];
      if (!validTypes.includes(event.event_type)) continue;

      rows.push({
        schema_version: event.v,
        event_type: event.event_type,
        rstack_version: String(event.rstack_version).slice(0, 20),
        os: String(event.os).slice(0, 20),
        arch: event.arch ? String(event.arch).slice(0, 20) : null,
        event_timestamp: event.ts,
        skill: event.skill ? String(event.skill).slice(0, 50) : null,
        session_id: event.session_id ? String(event.session_id).slice(0, 50) : null,
        duration_s: typeof event.duration_s === "number" ? event.duration_s : null,
        outcome: String(event.outcome).slice(0, 20),
        error_class: event.error_class ? String(event.error_class).slice(0, 100) : null,
        error_message: event.error_message ? String(event.error_message).slice(0, 100) : null,
        failed_step: event.failed_step ? String(event.failed_step).slice(0, 50) : null,
        used_browse: event.used_browse === true,
        concurrent_sessions: typeof event.sessions === "number" ? event.sessions : 1,
        installation_id: event.installation_id ? String(event.installation_id).slice(0, 64) : null,
        // Research-specific fields
        compute_provider: event.compute_provider ? String(event.compute_provider).slice(0, 20) : null,
        gpu_type: event.gpu_type ? String(event.gpu_type).slice(0, 20) : null,
        venue: event.venue ? String(event.venue).slice(0, 20) : null,
        pipeline_stage: event.pipeline_stage ? String(event.pipeline_stage).slice(0, 50) : null,
      });

      // Track installations for upsert
      if (event.installation_id) {
        installationUpserts.set(event.installation_id, {
          version: event.rstack_version,
          os: event.os,
        });
      }
    }

    if (rows.length === 0) {
      return new Response(JSON.stringify({ inserted: 0 }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Insert events
    const { error: insertError } = await supabase
      .from("telemetry_events")
      .insert(rows);

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Upsert installations (update last_seen)
    for (const [id, data] of installationUpserts) {
      await supabase
        .from("installations")
        .upsert(
          {
            installation_id: id,
            last_seen: new Date().toISOString(),
            rstack_version: data.version,
            os: data.os,
          },
          { onConflict: "installation_id" }
        );
    }

    return new Response(JSON.stringify({ inserted: rows.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch {
    return new Response("Invalid request", { status: 400 });
  }
});
