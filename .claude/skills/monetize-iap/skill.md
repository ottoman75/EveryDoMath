---
name: monetize-iap
description: EveryDoMath IAP 수익화 스킬. familyShareable 수정, 구독 상품 추가, IAPStoreView 개선을 수행. IAP 관련 변경 요청 시 반드시 이 스킬을 사용할 것.
---

# IAP 수익화 구현 스킬

프로젝트 경로: `/Users/otto/DevWork/EveryDoMath`

## 작업 1: familyShareable: true

`EveryDoMath/EveryDoMath.storekit` 파일에서 모든 `"familyShareable": false`를 `"familyShareable": true`로 변경한다. (5개 상품 전부)

## 작업 2: 연간/월간 구독 상품 추가

`.storekit` 파일의 `"subscriptionGroups": []`를 아래로 교체한다:

```json
"subscriptionGroups": [
  {
    "id": "EDMPREMIUM001",
    "localizations": [
      { "description": "EveryDoMath 전체 학년 프리미엄 구독", "displayName": "EveryDoMath 프리미엄", "locale": "ko_KR" },
      { "description": "EveryDoMath All Grades Premium Subscription", "displayName": "EveryDoMath Premium", "locale": "en_US" }
    ],
    "subscriptions": [
      {
        "adHocOfferCodeRedemptionEnabled": false,
        "displayPrice": "12900",
        "familyShareable": true,
        "groupNumber": 1,
        "internalID": "A1B2C3E1",
        "introductoryOffer": {
          "duration": 1,
          "durationUnit": "WEEK",
          "mode": "FREE_TRIAL",
          "numberOfPeriods": 1
        },
        "localizations": [
          { "description": "3~6학년 전체 무제한 + 가족 공유", "displayName": "연간 프리미엄", "locale": "ko_KR" },
          { "description": "All grades unlimited + Family Sharing", "displayName": "Annual Premium", "locale": "en_US" }
        ],
        "productID": "com.everydomath.subscription.yearly",
        "referenceName": "Annual Premium",
        "recurringSubscriptionPeriod": "P1Y",
        "subscriptionGroupID": "EDMPREMIUM001",
        "type": "RecurringSubscription"
      },
      {
        "adHocOfferCodeRedemptionEnabled": false,
        "displayPrice": "1900",
        "familyShareable": true,
        "groupNumber": 2,
        "internalID": "A1B2C3E2",
        "introductoryOffer": {
          "duration": 1,
          "durationUnit": "WEEK",
          "mode": "FREE_TRIAL",
          "numberOfPeriods": 1
        },
        "localizations": [
          { "description": "3~6학년 전체 무제한 + 가족 공유", "displayName": "월간 프리미엄", "locale": "ko_KR" },
          { "description": "All grades unlimited + Family Sharing", "displayName": "Monthly Premium", "locale": "en_US" }
        ],
        "productID": "com.everydomath.subscription.monthly",
        "referenceName": "Monthly Premium",
        "recurringSubscriptionPeriod": "P1M",
        "subscriptionGroupID": "EDMPREMIUM001",
        "type": "RecurringSubscription"
      }
    ]
  }
]
```

## 작업 3: IAPManager.swift 수정

`/Users/otto/DevWork/EveryDoMath/EveryDoMath/Data/Repository/IAPManager.swift`

### 3-1. ProductID에 구독 상품 추가
```swift
static let subscriptionMonthly = "com.everydomath.subscription.monthly"
static let subscriptionYearly = "com.everydomath.subscription.yearly"

static var subscriptions: [String] { [subscriptionMonthly, subscriptionYearly] }
static var all: [String] { [grade3, grade4, grade5, grade6, allGrades, subscriptionMonthly, subscriptionYearly] }
```

### 3-2. hasActiveSubscription 프로퍼티 추가
```swift
var hasActiveSubscription: Bool {
    purchasedIds.contains(ProductID.subscriptionMonthly) ||
    purchasedIds.contains(ProductID.subscriptionYearly)
}
```

### 3-3. isGradeUnlocked에 구독 체크 추가
`if purchasedIds.contains(ProductID.allGrades)` 앞에 삽입:
```swift
if hasActiveSubscription { return true }
```

### 3-4. 구독 상품 구매 후 자동 dismiss용 프로퍼티 추가 (필요 시)
구독 구매는 기존 `purchase()` 메서드로 처리 가능 — 추가 코드 불필요.

## 작업 4: IAPStoreView.swift 전면 개편

`/Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/IAP/IAPStoreView.swift`

### 구조 변경
1. **header**: 기존 유지, 단 subtitle을 value proposition 3개 stat으로 교체
2. **subscriptionSection**: 구독 카드 2개 (연간=BEST, 월간) - 상품 목록 위에 배치
3. **divider**: "또는 개별 학년 구매" 구분선
4. **productList**: 기존 학년별 카드 (변경 없음)

### valuePropsRow (header 아래에 추가)
```swift
private var valuePropsRow: some View {
    HStack(spacing: 0) {
        propItem(icon: "doc.text.fill", label: "14,000문제")
        Divider().frame(height: 28)
        propItem(icon: "graduationcap.fill", label: "교육과정 연계")
        Divider().frame(height: 28)
        propItem(icon: "person.2.fill", label: "가족 공유")
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCardBorder, lineWidth: 1))
    .padding(.horizontal, 20)
}

private func propItem(icon: String, label: String) -> some View {
    VStack(spacing: 4) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.appPrimaryStart)
        Text(verbatim: label)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.appSubtext)
    }
    .frame(maxWidth: .infinity)
}
```

### subscriptionSection
구독 상품 목록을 `iap.products`에서 필터링:
```swift
var subscriptionProducts: [Product] {
    iap.products.filter {
        $0.id == IAPManager.ProductID.subscriptionYearly ||
        $0.id == IAPManager.ProductID.subscriptionMonthly
    }
    .sorted { $0.price > $1.price } // 연간 먼저
}

var nonSubscriptionProducts: [Product] {
    iap.products.filter {
        $0.id != IAPManager.ProductID.subscriptionYearly &&
        $0.id != IAPManager.ProductID.subscriptionMonthly
    }
}
```

각 구독 카드:
- 연간 상품: 상단에 "🔥 7일 무료 체험" 뱃지, CTA 버튼 텍스트 "7일 무료로 시작"
- 월간 상품: 일반 카드, CTA "시작하기"
- 이미 구독 중이면 checkmark 표시

구독 카드 내 가격 표시:
- 연간: `₩12,900/년` + 아래 작은 글씨로 `(월 ₩1,075 상당)`
- 월간: `₩1,900/월`

### 분리선
```swift
private var orDivider: some View {
    HStack(spacing: 12) {
        Rectangle().fill(Color.appCardBorder).frame(height: 1)
        Text("iap.or_individual")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.appSubtext)
            .fixedSize()
        Rectangle().fill(Color.appCardBorder).frame(height: 1)
    }
    .padding(.horizontal, 20)
}
```

### body 순서
```
header → valuePropsRow → subscriptionSection → orDivider → productList → restoreButton → legal
```

## 작업 5: Localizable.strings 추가

모든 언어 파일(`ko.lproj`, `en.lproj`, `ja.lproj`)에 추가:

**ko.lproj:**
```
"iap.or_individual" = "또는 개별 학년 구매";
"iap.free_trial_badge" = "7일 무료 체험";
"iap.start_free_trial" = "7일 무료로 시작";
"iap.start_subscription" = "시작하기";
"iap.per_year" = "/년";
"iap.per_month" = "/월";
"iap.year_equivalent" = "(월 ₩1,075 상당)";
"iap.active_subscription" = "구독 중";
```

**en.lproj:**
```
"iap.or_individual" = "Or purchase by grade";
"iap.free_trial_badge" = "7-Day Free Trial";
"iap.start_free_trial" = "Start Free Trial";
"iap.start_subscription" = "Subscribe";
"iap.per_year" = "/year";
"iap.per_month" = "/month";
"iap.year_equivalent" = "(~₩1,075/mo)";
"iap.active_subscription" = "Active";
```

**ja.lproj:**
```
"iap.or_individual" = "または学年別購入";
"iap.free_trial_badge" = "7日間無料体験";
"iap.start_free_trial" = "無料で始める";
"iap.start_subscription" = "始める";
"iap.per_year" = "/年";
"iap.per_month" = "/月";
"iap.year_equivalent" = "(月約₩1,075相当)";
"iap.active_subscription" = "利用中";
```

## 주의사항
- `monetize-trial` 에이전트가 `HomeView.swift`를 수정 중 — 해당 파일 건드리지 말 것
- 기존 `iap.*` 키는 유지, 신규 키만 추가
- `.storekit`의 `nonRenewingSubscriptions`는 빈 배열 유지
