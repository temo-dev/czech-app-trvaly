import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export const GUEST_ACCESS_HEADER = "x-guest-token";

export function getGuestToken(req: Request): string | null {
  return normalizeString(req.headers.get(GUEST_ACCESS_HEADER));
}

export function isServiceRoleRequest(req: Request): boolean {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) return false;

  const authHeader = req.headers.get("Authorization");
  if (authHeader === `Bearer ${serviceRoleKey}`) {
    return true;
  }

  return req.headers.get("apikey") === serviceRoleKey;
}

export async function getAuthUserId(
  supabase: SupabaseClient,
  req: Request,
): Promise<string | null> {
  if (isServiceRoleRequest(req)) return null;

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const token = authHeader.replace("Bearer ", "");
  const { data: { user } } = await supabase.auth.getUser(token);
  return user?.id ?? null;
}

export function assertCanAccessOwnedRow(args: {
  req: Request;
  row: Record<string, unknown>;
  requesterUserId: string | null;
}): void {
  const { req, row, requesterUserId } = args;
  if (isServiceRoleRequest(req)) return;

  const ownerId = normalizeString(row["user_id"]);
  if (ownerId != null) {
    if (ownerId !== requesterUserId) {
      throw new Error("Forbidden");
    }
    return;
  }

  const rowGuestToken = normalizeString(row["guest_token"]);
  const requestGuestToken = getGuestToken(req);
  if (rowGuestToken == null || requestGuestToken == null) {
    throw new Error("Forbidden");
  }
  if (rowGuestToken !== requestGuestToken) {
    throw new Error("Forbidden");
  }
}

export async function assertCanAccessExamAttempt(args: {
  supabase: SupabaseClient;
  req: Request;
  attemptId: string;
}): Promise<Record<string, unknown>> {
  const { supabase, req, attemptId } = args;
  const { data: attempt } = await supabase
    .from("exam_attempts")
    .select("id, user_id, guest_token")
    .eq("id", attemptId)
    .maybeSingle();

  if (!attempt) {
    throw new Error("Attempt not found");
  }

  const requesterUserId = await getAuthUserId(supabase, req);
  assertCanAccessOwnedRow({
    req,
    row: attempt as Record<string, unknown>,
    requesterUserId,
  });

  return attempt as Record<string, unknown>;
}

function normalizeString(value: unknown): string | null {
  if (value == null) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}
