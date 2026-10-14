# Chat interface

`/chat-detail` keeps the selected `ChatConversation` and its existing message
provider. The white conversation view uses Montserrat, light gray incoming
bubbles and black outgoing bubbles. Each original timestamp sits below its
bubble, aligned with its sender.

The fixed header shows the mechanic's initials, name and actual rescue status.
The vehicle plate appears above the conversation. The phone button delegates to
the existing `ChatService.call`; launch failures retain the fallback phone
number. The overflow menu opens contact details or the same call action.

The gray footer contains a white rounded text field, send button and camera.
The “+” button reveals the three existing horizontally scrolling quick replies.
Opening, using and closing that panel preserves a typed draft. Photo selection,
camera/gallery errors, text submission, the two-second demo reply and automatic
scrolling above the keyboard keep their existing provider behavior.

Conversation records, message text and demo reply content remain in
`chat/data/`, `ChatService` and `ChatMessagesController`. This UI change does not
add delivery, online presence or voice messages. Conversations retain their
existing session lifetime.

Review captures: [conversation](screenshots/chat-monochrome.png),
[quick replies](screenshots/chat-monochrome-quick-replies.png) and
[320px keyboard layout](screenshots/chat-monochrome-keyboard.png).
`test/chat_detail_screen_test.dart` covers message and attachment retention,
quick replies, calling, contact details and keyboard scrolling.
