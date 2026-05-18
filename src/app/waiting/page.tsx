export default function WaitingPage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-zinc-900 via-zinc-800 to-zinc-900 px-6">
      <div className="w-full max-w-sm text-center">
        <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-zinc-700 mb-6">
          <span className="text-4xl">⏳</span>
        </div>
        <h1 className="text-2xl font-bold text-white mb-3">승인 대기 중</h1>
        <p className="text-zinc-400 text-sm leading-relaxed">
          가입 신청이 완료되었습니다.
          <br />
          운영자가 확인 후 승인해 드리면
          <br />
          서비스를 이용하실 수 있습니다.
        </p>
        <div className="mt-8 bg-zinc-800/60 border border-zinc-700 rounded-xl p-4">
          <p className="text-xs text-zinc-500">
            승인 관련 문의는 운영자에게 카카오톡으로 연락해 주세요.
          </p>
        </div>
      </div>
    </main>
  );
}
