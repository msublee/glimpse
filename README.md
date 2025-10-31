# Glimpse

<p align="center">
  <img src="Sources/Glimpse/Resources/Assets.xcassets/AppIcon.appiconset/GlimpseIcon-512.png" width="128" height="128" alt="Glimpse Icon">
</p>

<p align="center">
  <strong>macOS용 빠른 웹 검색 런처</strong><br>
  단축키 한 번으로 구글 검색
</p>

## 주요 기능

- 전역 단축키 (`⌃⇧Space`)로 즉시 실행
- Floating 오버레이 창
- 구글 로그인 지원 (세션 유지)
- 검색 히스토리 (최대 15개)
- 키보드 단축키 (`⌘B`, `⌘H`, `⌘R`, `⌘/`)

## 설치

### 요구사항
- macOS 13.0 이상
- Swift 6.2 이상

### 빌드

```bash
git clone https://github.com/msublee/glimpse.git
cd glimpse
swift build -c release
Scripts/package_app.sh release
cp -R .build/release/Glimpse.app /Applications
```

## 사용법

### 기본 사용
1. `⌃⇧Space` - 앱 열기
2. 검색어 입력
3. `Return` - 검색 실행

### 단축키

| 단축키 | 기능 | 설명 |
|--------|------|------|
| `⌃⇧Space` | 앱 열기/닫기 | 전역 단축키. 어떤 앱에서든 실행 가능. Preferences에서 변경 가능 |
| `⌘B` | 검색 히스토리 | 최근 검색 사이드바 토글. 최대 15개 저장 |
| `⌘H` | 홈으로 이동 | 구글 홈페이지로 이동. 검색창 비워지고 포커스 |
| `⌘R` | 새로고침 | 현재 페이지 새로고침 |
| `⌘/` | 포커스 전환 | Glimpse 검색창 ↔ 구글 검색창 전환 |
| `Esc` | 창 닫기 | 검색창 초기화하고 닫기 |

### 로그인
- 우측 상단 "Sign in" 버튼 클릭
- 구글 계정으로 로그인
- ✅ "Signed in" 표시
- 앱 재시작 후에도 로그인 유지
- 개인화된 검색 결과

## 개발

이 프로젝트는 **Codex**와 **Claude Code**를 사용하여 작성되었습니다.

## 라이선스

MIT License
