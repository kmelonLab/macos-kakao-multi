![카카오톡 다중 실행 주의사항 포스터](./poster.png)

# kakao-multi

macOS에서 카카오톡 앱을 분리된 이름과 설정으로 복제해 여러 인스턴스를 실행하기 위한 스크립트입니다.

> 주의: 본 방법 사용 시 계정 정지, 재로그인 제한, 인증 실패, 기기 연결 해제 등 서비스 이용 제재나 앱 안정성 문제가 발생할 수 있습니다. 충분히 검토한 뒤 신중하게 사용하세요.

## 사용 전 주의사항

카카오톡은 자동화된 안티어뷰징 시스템과 운영정책을 통해 비정상 이용을 탐지하고 제한할 수 있습니다. 다중 실행 자체보다 **자동화, 대량 계정 운영, 스팸, 우회 목적 사용**이 더 큰 위험 요소입니다.

- 사용하는 계정이 모두 본인 소유인지 확인합니다.
- 계정 공유, 타인 명의 사용, 허위 계정 사용을 피합니다.
- 메시지 자동 발송, 친구 자동 추가, 오픈채팅 홍보 자동화 용도로 사용하지 않습니다.
- 비공식 API, 앱 변조, 인증 우회, 네트워크 패킷 조작은 사용하지 않습니다.
- 같은 계정으로 반복 로그인하거나, 계정을 짧은 시간 안에 계속 교체하지 않습니다.
- 문제가 발생하면 즉시 사용을 중단하고 공식 고객센터 또는 계정 보호 절차를 따릅니다.

## 위험도가 높은 사용 패턴

| 사용 패턴 | 위험도 |
| --- | --- |
| 오픈채팅 대량 홍보 | 매우 높음 |
| 친구 자동 추가 | 매우 높음 |
| 메시지 자동 발송 | 매우 높음 |
| 비공식 API 사용 | 높음 |
| 앱 바이너리 수정 또는 인증 우회 | 높음 |
| 계정 수십 개 운영 | 높음 |
| 로그인 반복 또는 잦은 기기 변경 | 중간~높음 |
| VPN/IP를 계속 바꿔가며 접속 | 높음 |

## 상대적으로 안전한 사용 원칙

- 개인 계정과 업무 계정을 분리하는 정도로만 사용합니다.
- 모든 조작은 사용자가 직접 수동으로 수행합니다.
- 정상적인 대화, 업무 응답, 테스트 범위 안에서 사용합니다.
- 스팸, 광고, 대량 발송, 자동화 도구와 함께 사용하지 않습니다.
- macOS 사용자 계정, 앱 컨테이너, 데이터 경로를 분리해 세션과 캐시 충돌을 줄입니다.

## 설정

`kakao_multi.sh`는 같은 폴더의 `.env` 파일을 자동으로 읽어서 생성 개수, `.app` 파일명, Finder의 응용 프로그램 목록에서 보이는 표시 이름을 설정합니다.

기존 `.env`를 수정해서 사용하거나, 필요하면 `.env.example`를 `.env`로 복사해서 사용합니다.

```bash
cp .env.example .env
```

기본 예시는 아래와 같습니다.

```dotenv
KAKAO_MULTI_COUNT=4
KAKAO_MULTI_APP_NAME_PREFIX="카카오톡-r"
KAKAO_MULTI_DISPLAY_NAME_PREFIX="카카오톡-r"
KAKAO_MULTI_NUMBER_WIDTH=2
KAKAO_MULTI_BUNDLE_ID_PREFIX="com.kakao.multi"
BASE_APP="/Applications/KakaoTalk.app"
TARGET_DIR="/Applications"
```

- `KAKAO_MULTI_COUNT`: 생성할 카카오톡 앱 개수
- `KAKAO_MULTI_APP_NAME_PREFIX`: 생성되는 `.app` 파일명 접두사. Finder가 파일명을 기준으로 보여주는 경우까지 고려하면 이 값도 한글로 두는 것이 가장 확실합니다.
- `KAKAO_MULTI_DISPLAY_NAME_PREFIX`: Finder의 응용 프로그램 목록, Launchpad 등에서 보이는 표시 이름 접두사. 기본값은 `카카오톡-r`입니다.
- `KAKAO_MULTI_NUMBER_WIDTH`: 번호 자릿수
- `KAKAO_MULTI_BUNDLE_ID_PREFIX`: 앱별 고유 Bundle ID 접두사
- `BASE_APP`: 원본 카카오톡 앱 경로
- `TARGET_DIR`: 복제 앱이 생성될 경로

예를 들어 아래처럼 설정하면:

```dotenv
KAKAO_MULTI_COUNT=3
KAKAO_MULTI_APP_NAME_PREFIX="카카오톡-r"
KAKAO_MULTI_DISPLAY_NAME_PREFIX="카카오톡-r"
```

아래처럼 생성됩니다.

```text
/Applications/카카오톡-r01.app
/Applications/카카오톡-r02.app
/Applications/카카오톡-r03.app
```

Finder 표시 이름은 각각 `카카오톡-r01`, `카카오톡-r02`, `카카오톡-r03`으로 보입니다.

KakaoTalk는 `LSHasLocalizedDisplayName=true`를 사용하므로, 이 스크립트는 `Info.plist`뿐 아니라 `Resources/*.lproj/InfoPlist.strings`도 함께 수정하고, LaunchServices 재등록까지 수행합니다.

`.env` 파일이 없으면 기본값으로 `카카오톡-r01`부터 `카카오톡-r04`까지 생성됩니다.

## 실행

```bash
chmod +x kakao_multi.sh
./kakao_multi.sh
```

## macOS에서 발생할 수 있는 문제

카카오톡 Mac 앱은 기본적으로 단일 앱 실행을 전제로 동작하는 부분이 있을 수 있습니다. 복제 앱을 여러 개 실행하면 다음 문제가 발생할 수 있습니다.

- 캐시 충돌
- 세션 꼬임
- 인증 해제
- 알림 충돌
- 로컬 DB 파일 충돌
- 앱 업데이트 후 복제 앱 실행 실패

문제가 반복되면 복제 앱을 삭제하고 원본 카카오톡 앱만 사용하는 상태로 되돌리는 것이 좋습니다.

## 결론

이 도구는 카카오톡을 자동화하거나 서비스 정책을 우회하기 위한 도구가 아닙니다. 본인 계정을 업무/개인 용도로 분리해 수동으로 사용하는 경우에도 서비스 정책, 계정 보안, 앱 안정성 문제가 생길 수 있으므로 사용자는 충분히 검토한 뒤 신중하게 사용해야 합니다.

## 참고 자료

- [카카오톡 자동감지 안내](https://talksafety.kakao.com/measure/detection?lang=ko)
- [카카오톡 운영정책](https://talksafety.kakao.com/en/policy)
- [카카오톡 허위 계정 운영정책](https://talksafety.kakao.com/policy/stability/fakeaccount)
- [KakaoTalk 공식 서비스 소개](https://www.kakaocorp.com/page/service/service/KakaoTalk?lang=ko)
