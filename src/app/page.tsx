"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");

  const supabase = createClient();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/dashboard`,
      },
    });

    if (error) {
      setError(error.message);
    } else {
      setSent(true);
    }
    setLoading(false);
  }

  return (
    <main className="min-h-screen bg-brand-light flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-brand-green rounded-2xl mb-4">
            <span className="text-white text-2xl font-bold">M</span>
          </div>
          <h1 className="text-2xl font-bold text-brand-dark">My Stockvel</h1>
          <p className="text-gray-500 mt-1">Treasury management for your group</p>
        </div>

        <div className="card">
          {sent ? (
            <div className="text-center py-4">
              <div className="text-4xl mb-3">📬</div>
              <h2 className="text-lg font-semibold text-brand-dark mb-2">
                Check your email
              </h2>
              <p className="text-gray-500 text-sm">
                We sent a magic link to <strong>{email}</strong>. Click it to sign in — no password needed.
              </p>
            </div>
          ) : (
            <>
              <h2 className="text-lg font-semibold text-brand-dark mb-1">
                Treasurer sign in
              </h2>
              <p className="text-gray-500 text-sm mb-6">
                Enter your email and we will send you a secure link.
              </p>
              <form onSubmit={handleLogin} className="space-y-4">
                <input
                  type="email"
                  className="input"
                  placeholder="treasurer@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
                {error && (
                  <p className="text-red-500 text-sm">{error}</p>
                )}
                <button
                  type="submit"
                  className="btn-primary w-full"
                  disabled={loading || !email}
                >
                  {loading ? "Sending..." : "Send magic link"}
                </button>
              </form>
            </>
          )}
        </div>

        <p className="text-center text-xs text-gray-400 mt-6">
          POPIA compliant · Data hosted in South Africa · No passwords stored
        </p>
      </div>
    </main>
  );
}
