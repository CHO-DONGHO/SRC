import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");

  if (code) {
    const supabase = await createClient();

    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      // 세션 교환 성공 → 유저 정보 조회
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (user) {
        // profiles row 확인 (handle_new_user 트리거로 자동 생성되지만 role 확인)
        const { data: profile } = await supabase
          .from("profiles")
          .select("role, is_active")
          .eq("id", user.id)
          .single();

        // 비활성(강퇴) 유저 처리
        if (profile?.is_active === false) {
          await supabase.auth.signOut();
          return NextResponse.redirect(
            `${origin}/login?error=inactive`
          );
        }

        // role에 따라 리다이렉트
        const destination =
          profile?.role === "WAITING" ? "/waiting" : "/dashboard";
        return NextResponse.redirect(`${origin}${destination}`);
      }
    }
  }

  // 실패 시 로그인 페이지로 리다이렉트
  return NextResponse.redirect(`${origin}/login?error=auth_failed`);
}
