# Admin Revo module

All Admin screens, widgets, models, sample catalogs, services and Riverpod state
live in `lib/features/admin/`. The only application integration change is adding
`adminRoutes` to the shared router. `core/theme/admin_tokens.dart` supplies the
blue `#1976D2`, red `#E53935`, white background, `#F8F9FA` cards,
`#1A1A1A` text and `#757575` secondary text. AdminTheme scopes a Google Fonts
Montserrat text theme to Admin, using bundled font assets for offline rendering.
Dashboard cards have 24 px corners and a Health-style hierarchy of category,
insight, comparison values and chart. Existing customer
and provider screens are unchanged.

## Admin typography

`theme/admin_typography.dart` defines the shared Montserrat roles. All explicit
Admin text styles use `GoogleFonts.montserrat`; `AdminTheme` also supplies these
roles to inherited text, form fields, chips, tables and Material buttons. Fonts
resolve from the existing bundled Regular, Medium, SemiBold, Bold and ExtraBold
assets, without adding dependencies or changing the asset manifest.

| Text role | Weight | Letter spacing |
| --- | --- | --- |
| Screen headings and large statistics/currency | Bold / ExtraBold | -0.5 px |
| Card headings and buttons | SemiBold / Bold | -0.3 px |
| Information labels and status | Medium | -0.2 px |
| Body text, captions and secondary descriptions | Regular | -0.2 px |

Existing text sizes, line heights, colors and component spacing are retained.
When overriding a shared style's weight, use `GoogleFonts.montserrat(textStyle:
baseStyle, fontWeight: ...)` to select the matching bundled font variant. A
`copyWith` that only changes size or color can retain the shared style directly.

Typography verification on 2026-10-18: all 451 repository tests passed. After
the final visual review, all 69 Admin/date-picker widget tests passed again;
static analysis reported no issues, all 351 Dart files passed the format check,
and the debug Android APK built successfully in the matching validation copy.
Mobile, desktop and 320 px layouts with enlarged text remain covered. The
review images below were regenerated for the shared typography.

## Open the sandbox

```bash
flutter run -t lib/features/admin/admin_preview.dart
```

This explicit preview entry point creates a sample ADMIN session. It does not
change the customer login's current development bypass. The normal app starts
without Admin permission; entering an Admin URL or adding `?role=ADMIN` cannot
grant access. The standalone preview ends at its signed-out page after logout;
restart it to get a fresh sample session.

## Navigation and behavior

| Route | View |
| --- | --- |
| `/admin` or `/admin/dashboard` | Today / 7 days / 30 days / custom dates; Health-style highlights and operational queues |
| `/admin/orders` | Search by ID/customer/provider; order, payment and inclusive calendar-date filters |
| `/admin/orders/:orderId` | Recorded timeline, coordinate map, offers, price/weather details, payment history, dispute and read-only chat |
| `/admin/providers` | Pending applications; open mechanic details; approve or reject with required reason |
| `/admin/providers/:providerId` | Full-screen mechanic profile, workshop/document gallery and fixed review actions |
| `/admin/finance` | FinBank balance selector, escrow card and invoice activity with reconciliation details |
| `/admin/requests` | Refunds, price disputes and withdrawals; combined red pending badge |
| `/admin/account` | Profile, credentials, configuration, staff shifts/roles, audit, login history, guide, support requests and confirmed logout |

Wide views use an extended NavigationRail and scrollable data tables. Tablets
use a compact rail. Phones use `AdminFloatingBottomNav`: six icon-only floating tabs in a white capsule,
16 px side/bottom margins, 30 px corners, soft shadow and an `#E8F0FE` active
pill. Names are available through tooltips and accessibility labels.
Overview, orders, provider approval, finance, requests and account are
available directly in both navigation layouts. The dashboard has no account
footer button. The request badge reflects the live combined pending count
(7 in the initial sample), including its loading/error states.
There is no AppBar or Revo/ADMIN banner above the content. Admin pages use
the shared `AdminPageHeader`: a left-aligned 22 px Montserrat Bold title in
`#1A1A1A`. The dashboard centers a 20 px “Tổng quan” title in the User-style sky
header, replacing the User location controls. Its left 44 px circular avatar
uses the saved Admin photo, or the User-style empty placeholder until one is
selected. Tapping it opens the account page. Only the dashboard header shows a circular notification button,
which opens pending requests; its red dot reflects a nonzero pending count.
Other headers omit avatar/profile shortcuts; the account page also remains
available through navigation. Long titles wrap beside the notification button.
The order list uses a compact 20 px title. Detail uses a centered 16 px SemiBold
title and a left Back button that preserves the applied order filters.
Admin scaffolds use a white background. The account page has a vertical gradient
from white to pastel blue `#9FD7F9`; finance uses blue-gray `#F1F4F8` content.
Bottom scroll padding keeps
last items reachable above the floating bar, including at 320 px and large text.

## Dashboard weather

`widgets/admin_weather_card.dart` contains `AdminWeatherCard`. The dashboard
reuses the User sky background with 20 px side margins and a 60 px header.
Its five category pills match the User station filters: stadium shape,
11 px Montserrat Medium, 7/9 px horizontal/vertical padding, `#111111` selected
background, `#F5F5F7` inactive background and `#77777C` inactive text. They inherit
the User theme and appear on white below the weather card, with 20 px side
padding and 16 px separation from the weather and overview cards.
The weather card uses the User's `#91C8EF` → `#80B3E6` gradient, 24 px corners
and the same subtle shadow. Temperature is white 32 px Bold, risk text is
13 px Regular in `#175D91` and the User's
`WeatherConditionIcon` supplies the raised sun/cloud illustration.

The card watches the shared `homeWeatherProvider` and saved
`adminAccountProvider.settings.weatherFactor`. Its white pill reflects the
actual configured factor, including normal ×1.0 and surcharge factors without
rounding away saved precision. This displays configuration; forecast changes
do not edit fees or recorded order prices. The existing weather adapter still
supplies the labeled sample forecast until a real adapter is connected.
Loading and error states invent no temperature and keep the factor visible;
Retry and dashboard pull-to-refresh reload weather. No location controls,
booking search, emergency quick actions, stations or services are included.

## Dashboard overview cards

The dashboard uses borderless cards with 24 px corners and a soft black shadow
at 3% opacity (10 px blur, 3 px downward offset). The SOS summary has a `#0A192F`
navy background, white 32 px ExtraBold count, 12 px SemiBold title and 11 px Regular
period/count caption.
Its receipt-and-truck illustration has a transparent PNG background. The system
status card uses `#EBF3FE`, a `#1A2B4C` heading and three columns separated by
faint vertical lines: total customers, online/total mechanics and pending/working
counts. Overview section headings are 14 px SemiBold, system metrics are 20 px
Bold and labels are 11 px Medium. The revenue summary is light gray
(`#F8F9FA`), with a blue 26 px ExtraBold total and a miniature daily bar chart.
The overview follows the shared Admin Montserrat hierarchy.
These styles are scoped to the dashboard; other Admin pages retain their surfaces.
The six-icon floating navigation is unchanged.

`widgets/admin_overview_cards.dart` contains the three summary widgets and
their presentation helpers. The PNG is bundled as
`assets/images/admin-rescue-invoice-truck.png`; it was created with the built-in
imagegen tool from the supplied invoice/truck reference. The exact extraction
prompt is saved in [the asset prompt](assets/admin-rescue-invoice-truck.prompt.txt).

The dashboard at `screens/admin_dashboard_screen.dart` starts with the shared
“Tổng quan” header and five horizontally scrolling filter chips: “Tất cả”,
“SOS & Đơn hàng”, “Thợ & Khách hàng”, “Doanh thu & Dòng tiền” and
“Yêu cầu chờ xử lý”. The chips use the same compact User filter styling
described above and retain their five Admin destinations.
Below weather, the default overview contains the navy SOS summary, the three-column system
status card and revenue with its miniature chart. The period dropdown sits in
the system card and updates all summary values and chart buckets together.
Detailed filters show the SOS summary/trend and urgent orders, the system card,
the full revenue chart, or the pending withdrawal/refund queue respectively.
SOS and revenue detail filters keep a period selector above the cards. The
selected period and custom date workflow are shared across all these views.
Loading, empty and error states retain a period selector above the state view,
so changing the date range remains possible when the system card is unavailable.
`fl_chart` renders a smooth cumulative red line with gradient fill and the
preceding equal-length period in gray, plus rounded daily revenue bars and a
dashed daily-average reference. The daily SOS average is labeled separately.
Charts have touch tooltips and semantic descriptions; detailed views include
expandable daily values, including refunds and wallet credits. The repository
retains all 15 metrics; the dashboard presents the requested summary and detailed
groups. Totals, averages, row counts and badges come from providers rather than
hardcoded illustration values. Seven-day charts retain all seven daily buckets,
including weekends.

Urgent orders prioritize searching/assigned cases, and financial previews show
pending withdrawals/refunds. These queues reflect the current backlog rather
than the chart period. Rows navigate to the existing order detail or request
list; withdrawal links open its tab through `?tab=withdrawals`.
The order map is an offline, labeled coordinate illustration, with the most
recent recorded provider timestamp; it does not claim to display live map tiles.

`widgets/admin_date_range_picker_dialog.dart` supplies the shared
`AdminDateRangePickerDialog` for the order filter and dashboard custom period.
It uses a white rounded dialog, Montserrat, a bold 22 px selected-range heading,
Monday-first calendar, bold month/year header and previous/next buttons. Swiping
left shows the previous month; swiping right shows the next. Blue endpoint
circles connect through pale blue range bands, including across week rows;
today has a subtle border/dot. A second tap can complete a same-day or reverse
range. Month transitions respect reduced motion.

The dialog restores the applied range and keeps edits local until “Áp dụng”.
Close, Back and outside dismissal discard the draft. Selection retains the
existing one-year-through-today bounds and disables future dates. The returned
calendar end date is inclusive; `pickAdminDateRange` converts it to the following
midnight for the data layer's exclusive end. The top actions stay visible while
calendar content scrolls on small/landscape screens with large text.

All data views use `AdminAsyncSection` for loading, empty, error/retry and
permission states. Important actions use `AdminActionDialog`. Rejection reasons
and dispute notes must contain non-whitespace text, up to 500 characters. The
note is reviewed in a separate confirmation step before submission. Failed
submissions retain the note and confirmation, expose Retry and commit no sample
data. Buttons and modal dismissal are disabled during submission. Session checks
discard late UI results from an identity that has signed out or changed.

The “Mô phỏng / Test mode (Sandbox)” banner is removed from all Admin pages
and dialogs. The repository continues to use the same session-only sample data.
Refunds are a read-only pending queue because the supplied API contract
specifies GET endpoints only.

## Request and mechanic review cards

`widgets/admin_review_card.dart` provides the shared tracking-style cards for
refunds, price disputes, withdrawals and mechanic applications. These pages
retain their white scaffold. Cards use `#F8F9FA`, 20 px corners, no border and a
3% black shadow with 10 px blur and a 3 px downward offset. The header pairs a
small identifier label and a 16 px Bold value with a status pill on the right;
it wraps at narrow widths or large text scales. Labels use 11 px Montserrat
Medium in `#8E8E93`; values use 14 px Regular in `#1A1A1A`.

Each card keeps two equal information columns, including on phones. Refunds
pair request source/amount, then reason/Sandbox ID, and omit customer identity.
Other request types retain their price, reply, wallet and time fields. Mechanic
cards retain contact details, vehicle, plate and registration time under a
“Mã hồ sơ:” header. Wide views show two cards per row; larger text switches back
to one card per row while retaining the paired fields inside each card.

The three horizontal milestones show receipt, processing and completion. A
pending review confirms receipt only. Approved and rejected decisions complete
processing; the status pill distinguishes their outcomes. Mechanic milestones
use “Đã nhận hồ sơ” and “Đang xét duyệt”. The existing model has no intermediate
processing state or completion timestamps, so the UI supplies neither. Mutations
still use the existing confirmation, reason and retry flow. Their buttons and
wallet/detail shortcuts use compact blue/red pills without dividers.

## Mechanic application details

`presentation/screens/admin_mechanic_detail_screen.dart` replaces the previous
`_ProviderDetails` dialog. The list's “Chi tiết” action pushes a direct-linkable
detail route outside the floating navigation shell. `AdminMechanicDetailScreen`
accepts an `AdminProviderApplication`; the route resolves its ID through the
authenticated `adminProviderDetailProvider`. Missing, loading, error/retry and
permission states retain a Back action to the application list.

The header shows the supplied workshop photograph, a dark fade, white circular
Back/bookmark controls and four rounded gallery tiles. A white sheet with 28 px
top corners holds the 22 px Montserrat Bold name, review status, gray profile
card, equipment/registration pills and document verification card. The white
bottom bar keeps the application ID, red rejection and blue approval buttons
visible while scrolling; compact widths and large text stack the identity above
the buttons. Bookmarking is local to the open detail view.

`AdminProviderApplication` carries optional workshop address, masked citizen ID,
verification flag, workshop/front/back/portrait photographs and additional
photos. `AdminMechanicPhoto` supports bundled assets and network locations;
image failures render a placeholder. Decisions preserve all this metadata.
Gallery/document taps open a full-screen image viewer with swipe and pinch zoom.
The additional-image count reflects actual supplied photos. The sample P-101
uses `Tiemsua1.png` and `Ảnh_thợ.png`; CCCD images have not been supplied, so
their tiles show “Chưa có ảnh” and the verification pill remains unverified.
Real document images and verified status come from the application data.

Approval/rejection still use `AdminActionDialog`, including required rejection
notes, separate confirmation, disabled submission controls and retry preserving
the draft. Success returns to the refreshed pending list and records the existing
audit event. Cancelling preserves the open profile. Both the detail and full-screen
viewer hide profile data after Admin access is revoked.

Review captures: [detail](screenshots/admin-mechanic-detail-mobile.png),
[documents](screenshots/admin-mechanic-documents-mobile.png),
[gallery](screenshots/admin-mechanic-gallery-mobile.png) and
[desktop](screenshots/admin-mechanic-detail-desktop.png).

Mechanic detail verification on 2026-10-18: all 451 repository tests passed,
followed by 76 Admin integration/repository tests after the final presentation
adjustments. Static analysis reported no issues, formatting passed for 350 Dart
files and the debug Android APK built successfully. Checks used the temporary
validation copy described under Finance, including its three restored legacy
assets; source/config/test changes were compared with the workspace.

## Admin orders

Order lists use dedicated `AdminOrderCard` widgets: light-gray `#F8F9FA`,
borderless 20 px surfaces with a 3% shadow, a bold 16 px order ID and a
status-colored 12 px pill.
Completed orders use `#E8F5E9`; other statuses retain their own semantic colors.
Three paired rows show customer/incident, assigned mechanic/final price and
creation time/payment. Labels are 11 px Montserrat Medium in `#8E8E93`; values
are 14 px Regular in `#1A1A1A`. The estimate and any financial warning remain
visible. Wide screens arrange two cards per row; compact screens keep the paired
fields inside one card per row. Text wraps without fixed card heights. The filter
panel uses the same light-gray surface and the detail button uses a white pill.

Detail opens with an unboxed tracking identity and progress directly on the
white page. A small inventory icon accompanies the 11 px Medium identifier
label, 14 px SemiBold code/copy action and compact status pill. Tapping the code
or copy icon copies the displayed order ID, with success/failure feedback.
Four 24 px progress markers retain the real rescue milestones; their captions
are 10 px Medium and recorded times are 10 px Regular. Future markers are gray.
Customer/rescue details, mechanic contact and vertical status history follow.
The gray information card
uses aligned label/value rows. `AdminOrderDetailsService` derives four progress
steps from typed recorded milestones, with compatibility for existing timeline
labels. Only the stored creation time supplies a fallback: missing acceptance,
start and completion observations remain pending, including for cancelled orders.
Unknown administrative events remain in chronological history without advancing
rescue progress. Neither diagram invents transition timestamps.

The map, offers, service/weather/travel breakdown, payment/refund events, dispute
and read-only conversation remain available in expandable supplementary sections.
The mechanic chat button opens that recorded conversation without a composer;
it does not introduce message delivery. Call opens the system dialer through the
existing injected URL launcher after phone validation. Missing, masked or invalid
mechanic contacts disable Call, and dialer failures show retry feedback.
`AdminOrder.customerPhone` and `providerPhone` are optional contact snapshots,
preserved when prices are resolved. Seeded contact numbers are synthetic sandbox
fixtures in `AdminMockData`; real adapters must supply the order's actual contacts.

The order redesign leaves `AdminFloatingBottomNav` and its six destinations
unchanged. Compact layouts and large text keep the same navigation clearance.

Order review captures: [mobile cards](screenshots/admin-orders-cards-mobile.png),
[card fields](screenshots/admin-order-card-mobile.png),
[desktop cards](screenshots/admin-orders-cards-desktop.png),
[detail](screenshots/admin-order-detail-mobile.png) and
[recorded status history](screenshots/admin-order-detail-history-mobile.png).

## Finance and reconciliation

`presentation/screens/admin_finance_screen.dart` supplies `AdminFinanceScreen`,
a stateful view with three quick pills: “Khách chuyển”, “Revo giữ” and “Ví thợ”.
The previous `AdminReconciliationScreen` remains a compatibility entry point.
The selected pill updates a white, borderless 24 px balance card on `#F1F4F8`,
with a 34 px Montserrat ExtraBold amount in `#253370`, sampled from the supplied
admin card's navy face. Its centered label is 13 px Bold; the transaction caption
is 11 px Regular. Three equally tall white quick-action tiles sit in a pale
`#E7EEF0` well, with 24 px filled download/wallet/wrench icons and 11 px
SemiBold labels. The selected tile has a stronger shadow and Bold navy label.
Amount transitions fade/slide over 240 ms and respect reduced motion.
`adminFinanceProvider` joins existing summary and reconciliation providers;
the initial sample totals are 1,350,000 / 910,000 / 280,000 VND. The latest
transaction caption uses recorded payment timestamps, with no invented time.

`widgets/admin_finance_cards.dart` also displays the supplied
`assets/images/Thẻ_visa_admin.png` in a white account card with an internal
14 px Bold “Tài khoản đối soát hệ thống” heading and a filled shield icon. Its
square margins are cropped only while rendering. `admin_invoice_activity.dart`
renders order/date, payment state and bold navy amounts in three aligned columns. Paid,
pending, refunded, anomalous and excluded records retain distinct labels.
Tapping a row opens a scrollable detail sheet with payment ID, collected,
refunded and wallet-credit amounts, reconciliation state and reason.
Wide screens place balance and escrow side by side. Compact screens stack
them; the invoice columns scroll horizontally when needed at large text sizes.
Loading, empty, permission and retry states keep the existing Admin behavior.
Finance review captures: [mobile](screenshots/admin-finance-mobile.png),
[invoice activity](screenshots/admin-finance-invoices-mobile.png) and
[desktop](screenshots/admin-finance-desktop.png).

The latest FinBank visual pass passed all 60 Admin widget tests, static analysis
and the debug Android build in the matching validation copy. Review captures
load bundled Montserrat ExtraBold so amount typography matches the app.

Finance verification on 2026-10-18: all 446 tests passed, static analysis reported
no issues, the format check passed for all 346 Dart files and the debug Android
APK built successfully. Checks ran in a temporary copy with matching source contents. The workspace
already lacked `rescue-tow.png`, `rescue-team.png` and `rescue-garage.png` despite
their existing pubspec entries. Those three assets were supplied only in the
validation copy; the workspace's deletions were preserved.

## Admin account

`AdminAccountScreen` remains at `screens/admin_account_screen.dart`, following
this repository's feature layout. It uses the same Admin theme and floating
navigation shell, with the shared 22 px “Tài khoản Quản trị” header and a
vertical gradient from white at the top through soft blue to `#9FD7F9` at the
bottom, scoped to this route. The gradient covers the full viewport, including
safe areas and the space behind the floating navigation. Configuration, audit/security
and information/support actions each occupy an independent white card with
18 px corners, no border and a 4% black shadow (8 px blur, 3 px downward offset).
Cards have a 12 px bottom margin, 24 px blue icons on the left, black 14 px
Montserrat SemiBold titles and muted chevrons on the right. Group titles are
black 16 px Montserrat Bold. Titles and subtitles wrap with the available width;
the Sandbox card keeps its switch and confirmation flow.
The profile/actions, reusable card/list primitives, editors and read-only sheets
are separate widgets. The logout action uses a pale red surface and still requires
confirmation, with failure/retry and session clearing handled by the existing
sign-out controller.

`adminAccountProvider` owns session-scoped profile/contact values, avatar bytes,
operating configuration, staff roles/duty and support drafts that have been
saved. Profile edits do not replace the authenticated session or reset order
and wallet state. Avatar selection uses the existing injected device service.
Editors validate fields, disable submission while saving, preserve drafts on
failure and commit only after the injected service succeeds. Late completions
cannot write into another or signed-out session.

`AdminAccountService` supplies injectable save boundaries for profile, settings,
roster and support. Its default adapter is in-memory; settings and saved support
requests last for the current session. The Sandbox switch updates the configured
Test Mode preference; it does not replace `adminRepositoryProvider`, connect to
production, alter recorded prices or perform payments. SOS sound is a saved
notification preference; a live notification adapter must consume it. No
notification delivery service, account/configuration API or support delivery
endpoint is assumed. Support forms explicitly describe their session-only
storage. The login view records the current Admin session and does not invent
past devices, IP addresses or geographic locations.

Password changes use the shared `profileAccountServiceProvider`, with the same
validation as the customer account. The default authentication service reports
that the endpoint is unavailable; it never claims a successful password change.
An authenticated adapter enables the complete submit/error/retry flow. Passwords
are held only in form controllers/the service call and never enter account state
or audit records.

Only a verified `AdminSession.canManageAdmins` claim enables the SUPER ADMIN
badge, changes to fees/weather/SOS coefficients or Sandbox, and staff role/shift
updates. Ordinary ADMIN sessions can edit their own profile and SOS sound
preference and view the account sections. The UI cannot grant SUPER ADMIN or
change its own session's authority. Real backend adapters must enforce the same
permissions. The explicit preview seeds `ADM-2026-88` / `admin@revo.vn` with
that claim; regular application routes continue to fail closed.

`adminAuditTrailProvider` records successful provider approvals/rejections,
dispute decisions, withdrawals and account/configuration changes. Failed,
cancelled or late operations do not add entries. Both account state and this
session log reset on logout. For production, supply server-managed roster,
login history and an append-only audit feed. The requested Admin module version
label is `v1.0.2 (Build 2026)`; the application release version is unchanged.

## Data and integration

`AdminRepository` documents every requested mock GET/PATCH contract.
`MockAdminRepository` keeps records only in the current ProviderScope/session;
no backend requests, real charges, payouts, storage or secrets are introduced.
The two refund queues are combined and deduplicated by ID. Badge counts refresh
after successful resolution and show an unknown/error indicator instead of a
false zero when loading fails.

Dashboard customer/provider counts describe the current registry. Order and
payment metrics/charts group records by the order's creation date within the
selected interval; withdrawal totals group requests by creation date. Start
dates are inclusive and end dates are exclusive in the data layer. The calendar
picker includes the full final selected day. Reconciliation includes all sample
records, with held funds = collected − refunded − credited to provider wallets.
Wallet opening balances are separately labeled in wallet history.

Approving a withdrawal consumes its locked amount; rejecting it unlocks that
amount into the available balance. Both preserve an audit entry. Already resolved
requests cannot be processed again. Resolving a price dispute changes the final
order price and records the note/timestamp without silently changing paid money.
That price change may require a later payment adjustment/reconciliation.

For the real login flow, populate the module with the backend-verified identity
and navigate only after setting the session:

```dart
ref.read(adminSessionProvider.notifier).setSession(AdminSession(
  id: identity.id,
  name: identity.name,
  email: identity.email,
  role: identity.role,
));
if (identity.role == 'ADMIN') context.go('/admin/dashboard');
```

Replace `adminRepositoryProvider` with an authenticated Dio implementation of
`AdminRepository`. The backend must enforce ADMIN for every endpoint; map HTTP
403 to `AdminException(message, forbidden: true)`. Also override
`adminSignOutServiceProvider` to revoke/clear the real authentication credentials.
The default logout clears only the module's mock session. Do not use the preview
session in production. No authentication API or wallet-history endpoint is
assumed by this module.

## Validation and review captures

Verified on 2026-10-18: all 443 repository tests passed (97 Admin tests),
`flutter analyze --no-pub` reported no issues, all 342 Dart files passed the
format check, and the debug Android APK built successfully. Updated review
captures cover all six shared headers, all five dashboard filters, mobile and
desktop order/review cards, detail progress/contact information, status history,
all three request tabs and mechanic approval cards.
The checks used an identical source copy under `/tmp` to avoid generated-file
read stalls in the desktop workspace. The floating navigation retains all six
destinations with icons, without visible names.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Admin tests cover role guards/direct links, combined badges, date/search filters,
loading/empty/error retry, two-step confirmation, required reasons, failed
mutations, duplicate submissions, wallet conservation, reconciliation, session
changes/logout, desktop tables/tablet rails and 320 px layouts at 1.5 text scale.
Health dashboard coverage also verifies period comparison across New Year,
chart totals/averages, five content filters, six floating destinations, scroll clearance, account
access and the direct withdrawal-tab shortcut. Shared-header tests verify that
only the dashboard shows the avatar and notifications, its shortcuts open the
account and pending requests, the avatar reflects saved photo changes across
navigation, and an empty queue clears the dot. Weather layout coverage verifies
that the filter pills follow the weather card and precede the overview cards.
Date-picker tests cover typography/range colors, Monday alignment, both swipe
directions, month/year transitions, leap days, bounds, reverse/same-day ranges,
cancel/reopen, inclusive filtering and portrait/landscape at 1.5 text scale.
Account tests cover profile validation and navigation retention, configuration
validation/failure/retry, Sandbox confirmation, sound-setting cancellation,
staff role/shift updates, verified authority, password service delegation and
unavailable-service errors, support drafts, audit recording, duplicate writes,
late results after logout and 320 px editors with large text and the keyboard.
Review-card tests cover pending versus resolved/rejected milestones, retained
refund source/amount data, hidden customer identity, paired fields with long
values at 320 px and 1.5 text scale, and desktop card placement.
Order-header coverage verifies the displayed ID is copied, clipboard failures
remain retryable and the existing rescue progress stays intact.
To regenerate deterministic Flutter review images using bundled Montserrat
and enabled shadow blur during capture:

```bash
flutter test --no-pub --dart-define=CAPTURE_ADMIN=true test/admin_module_test.dart
```

Current shared headers: [overview](screenshots/admin-header-dashboard-mobile.png),
[orders](screenshots/admin-orders-cards-mobile.png),
[provider approval](screenshots/admin-header-providers-mobile.png),
[finance](screenshots/admin-header-finance-mobile.png),
[requests](screenshots/admin-header-requests-mobile.png),
[account](screenshots/admin-header-account-mobile.png).

Review images: [dashboard desktop](screenshots/admin-dashboard-desktop.png),
[dashboard mobile](screenshots/admin-dashboard-mobile.png),
[revenue mobile](screenshots/admin-dashboard-revenue-mobile.png),
[SOS/orders mobile](screenshots/admin-dashboard-sos-mobile.png),
[customers/providers mobile](screenshots/admin-dashboard-people-mobile.png),
[pending requests mobile](screenshots/admin-dashboard-pending-mobile.png),
[provider approval mobile](screenshots/admin-providers-mobile.png),
[provider approval desktop](screenshots/admin-providers-desktop.png),
[finance desktop](screenshots/admin-finance-desktop.png),
[refund requests mobile](screenshots/admin-requests-refunds-mobile.png),
[price disputes mobile](screenshots/admin-requests-disputes-mobile.png),
[withdrawal requests mobile](screenshots/admin-requests-mobile.png),
[requests desktop](screenshots/admin-requests-desktop.png),
[order date-range picker](screenshots/admin-orders-date-range-mobile.png),
[Admin account](screenshots/admin-account-mobile.png),
[account settings](screenshots/admin-account-settings-mobile.png),
[account security/support](screenshots/admin-account-security-mobile.png).
