# Service and mechanic rating

`ServiceRatingScreen` is a stateful Riverpod screen at
`/service-rating?id=<completed order ID>`. A completed invoice's “Đánh giá chi
tiết” button opens it with the same order ID. The invoice's existing quick-star
rating remains available. Unknown IDs and unfinished/cancelled orders show a
recoverable message instead of an unrelated sample review form.

## Presentation

The screen uses a white background, black Montserrat text and `#E53935` accents.
Its white AppBar has a gray Back control and “Đánh giá dịch vụ” title. A
`#F8F9FA` card with 16px corners displays the assigned mechanic's initials,
name, shop, selected services and actual order total. Missing contact metadata
uses explicit placeholders rather than fabricated names or prices.

`RatingStars` provides five accessible choices from 1 to 5; selection remains in
the screen's `_selectedStars`. `QuickTags` renders the five requested emoji
labels from `data/service_rating_tags.dart` and supports multiple selections.
Selected chips use a red border/text with `#FFEBEE` fill. The comment field has
12px corners and is optional, limited to 1,000 user-perceived characters.

`ImagePickerBox` invokes the shared `attachmentProvider` / `image_picker` gallery
boundary. It shows the selected photo with an accessible remove control and
allows replacement. Cancelling selection retains an existing photo. Errors
remain visible and can be retried. The existing 1,600px / quality 85 / 5 MB
settings apply; no new package or platform permissions were added.

The form scrolls while the red “GỬI ĐÁNH GIÁ” and gray “Bỏ qua” controls remain
at the bottom, including above a keyboard. Submission requires a star selection;
tags, comment and image may stay empty. Successful submission displays “Cảm ơn
bạn đã đánh giá!” and navigates to `/trang-chu` (`TrangChu` / `HomeScreen`).
Skip goes directly Home without saving a draft. Back returns to the previous
route, or Home when opened directly. Pending submission disables duplicate
send/skip/back; a failed submission preserves the draft for retry.

## State and persistence

`ServiceRatingService` derives summary values, validates the completed order,
stars and known tags, trims the comment and constructs an immutable review with
an injectable clock. Review image bytes and tag sets are copied before an async
submitter receives them. `ServiceRatingsController` prevents duplicate requests
per order, delegates submission, updates the shared Activity star rating and
retains the detailed review by order ID. Reopening restores the confirmed
comment/tags/photo and the current shared star rating.

`serviceRatingSubmitterProvider` is the injectable API boundary. Its default
implementation performs no network request: reviews remain in the current
ProviderScope and reset on app restart, matching the existing Activity demo.
Replace that provider with the project's backend review/upload adapter when an
endpoint is available. The default screen keeps image bytes in memory and adds
no upload or persistent photo storage. Failed remote submission does not update local stars or
retain a submitted review. Late gallery results cannot replace another order's
draft or update a disposed screen.

## Review and checks

Screenshots: [rating form](screenshots/service-rating.png),
[photo preview](screenshots/service-rating-photo.png), and
[320px / 1.5x text with reserved keyboard area](screenshots/service-rating-keyboard.png).
They use Montserrat and the requested example mechanic/service as injected order
data. The photo capture uses an existing garage asset for review only.

`test/service_rating_screen_test.dart` covers invoice navigation, actual summary
values, star/tag interactions and colors, full review persistence and immutable
bytes, optional fields, skip/back, gallery cancel/removal/error, submission
failure/retry and duplicates, invalid orders, late gallery results, Unicode
comment limits and small-screen keyboard usability. Existing Activity tests
retain the quick rating, complaints, invoice and rebooking behavior.

Run Dart formatting, `flutter analyze`, `flutter test`, and
`flutter build apk --debug` before publishing changes.
