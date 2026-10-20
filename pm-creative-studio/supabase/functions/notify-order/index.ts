// Supabase Edge Function "notify-order" — emails the customer via Resend.
// Setup: supabase secrets set RESEND_API_KEY=... FROM_EMAIL="PM Creative Studio <orders@yourdomain.com>" SITE_URL=https://yoursite.com
// Then Dashboard > Database > Webhooks: table "orders", events Insert + Update, target this function.
Deno.serve(async (req) => {
  const { type, record: r, old_record: o } = await req.json();
  if (!r?.customer_email) return new Response("skip");
  let subject = "", body = "";
  if (type === "INSERT") { subject = `Order ${r.ref} received`; body = `We received your order "${r.title}". We'll review it and update you here.`; }
  else if (r.deliverable_path && r.deliverable_path !== o?.deliverable_path) { subject = `Order ${r.ref} is ready to download`; body = `Your files for "${r.title}" are ready. Sign in to your dashboard to download them.`; }
  else if (r.status !== o?.status) { subject = `Order ${r.ref}: ${r.status.replace("_", " ")}`; body = `Your order "${r.title}" is now "${r.status.replace("_", " ")}".`; }
  else return new Response("skip");
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: Deno.env.get("FROM_EMAIL"), to: r.customer_email, subject,
      html: `<p>${body}</p><p><a href="${Deno.env.get("SITE_URL")}/#/client">Open my dashboard</a></p><p>PM Creative Studio — Creativity Meets Technology.</p>` }),
  });
  return new Response(res.ok ? "sent" : await res.text(), { status: res.ok ? 200 : 502 });
});
