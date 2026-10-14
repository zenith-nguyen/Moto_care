# Flutter device services

This layer bridges MotoCare controllers to device GPS and single-image
selection without putting plugin calls in widgets.

## Provider foreground GPS

Use `providerLocationTrackingControllerProvider` for the Provider app:

1. Call `goOnline()` when the Provider chooses to become available. It obtains
   a fresh device position, uploads it, then changes server presence to online.
2. While waiting, the controller refreshes location every 45 seconds.
3. After accepting an order, call `trackOrder(orderId)`. It immediately uploads
   a position and then refreshes every 5 seconds for the active order.
4. When the order ends, call `resumeWaiting()` if the Provider remains online.
5. Call `goOffline()` when the Provider turns availability off.

The controller exposes mode, order ID, last successful point/time, current
action, and last failure. A permission/service failure never turns the Provider
online. `openRecoverySettings()` opens location settings when the service is
off, otherwise app settings for permission recovery.

This is foreground tracking. Android/iOS may pause Dart timers when the app is
backgrounded and stops them when the app is killed. MotoCare deliberately does
not request background location in this milestone. The UI must explain this
instead of promising continuous tracking.

Android requests coarse and fine location together because users may choose
approximate location. iOS has a when-in-use description only.

## Chat image selection

Read `chatImagePickerProvider`, then call:

- `pick(ChatImageSource.camera)`; or
- `pick(ChatImageSource.gallery)`.

A cancelled picker returns `null`. A valid result is already a
`ChatImageUpload`, ready for `CustomerChatController.sendImage`. The adapter:

- accepts one image;
- rejects files larger than 5 MiB before reading/uploading them;
- recognizes JPEG, PNG, or WebP from file bytes rather than trusting the name
  or MIME value reported by the device;
- normalizes the filename;
- supports Android lost-data recovery through `recoverLostImage()`.

The UI should call lost-data recovery once when restoring the chat screen after
Android recreated the activity. It must still ask the user to confirm sending;
recovering a file must not automatically create a message.

## Error and lifecycle rules

- Never log image bytes, local paths, precise coordinates, or access tokens.
- Do not automatically retry chat sends or financial/order commands.
- GPS periodic updates may retry naturally on the next scheduled tick; show the
  last failure and last successful timestamp.
- Stop/dispose role controllers on logout. A new role session creates fresh
  tracking state.
- Test permission denied, service disabled, app background/resume, no network,
  oversized image, picker cancellation, and Android activity recreation on a
  physical device before the release APK.
