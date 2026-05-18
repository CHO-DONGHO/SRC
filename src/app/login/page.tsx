"use client";

import { createClient } from "@/utils/supabase/client";

export default function LoginPage() {
  const handleKakaoLogin = async () => {
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "kakao",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
  };

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-zinc-900 via-zinc-800 to-zinc-900 px-6">
      {/* 로고 영역 */}
      <div className="mb-12 text-center">
        <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-yellow-400 mb-5 shadow-lg shadow-yellow-400/30">
          <span className="text-4xl">🏃</span>
        </div>
        <h1 className="text-3xl font-bold text-white tracking-tight">
          수원러닝크루
        </h1>
        <p className="mt-2 text-zinc-400 text-sm">
          SRC 멤버 전용 러닝 기록 플랫폼
        </p>
      </div>

      {/* 로그인 카드 */}
      <div className="w-full max-w-sm bg-zinc-800/60 backdrop-blur-sm border border-zinc-700 rounded-2xl p-8 shadow-2xl">
        <h2 className="text-white text-lg font-semibold mb-1">로그인</h2>
        <p className="text-zinc-400 text-sm mb-8">
          카카오 계정으로 간편하게 시작하세요.
        </p>

        <button
          id="kakao-login-btn"
          onClick={handleKakaoLogin}
          className="w-full flex items-center justify-center gap-3 bg-yellow-400 hover:bg-yellow-300 active:scale-95 text-zinc-900 font-semibold rounded-xl py-3.5 transition-all duration-150 shadow-md shadow-yellow-400/20"
        >
          {/* 카카오 아이콘 (SVG) */}
          <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="currentColor"
            aria-hidden="true"
          >
            <path d="M12 3C6.477 3 2 6.582 2 11c0 2.826 1.76 5.31 4.42 6.868L5.4 21.55a.5.5 0 0 0 .72.55l4.36-2.9A11.76 11.76 0 0 0 12 19c5.523 0 10-3.582 10-8s-4.477-8-10-8z" />
          </svg>
          카카오로 로그인
        </button>

        <p className="mt-6 text-center text-xs text-zinc-500">
          SRC 멤버가 아닌 경우 운영자 승인 후 이용 가능합니다.
        </p>
      </div>
    </main>
  );
}
