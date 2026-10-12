# Revo Home image assets

## Weather backdrop

`HomeMediaAssets.weatherBackground` uses the supplied
`assets/images/Thời tiết.png` unchanged. The exact Unicode asset key is declared
in `pubspec.yaml` and loaded through Flutter's `AssetImage` with a light white
tint to match the reference's pastel blue. Its sky/cloud upper
area and white lower fade cover the Home header and weather card together;
search, filtering and quick-service controls remain Flutter widgets.

## Legacy Home video hero

The standalone `HomeVideoHero` retains its playback lifecycle and fake-platform
tests, but is not mounted on Home. Its earlier `home-video.mp4` and
`home-video-poster.jpg` files have been removed from the workspace, so their
stale bundle declarations were removed from `pubspec.yaml`. Restore those
assets and declarations before reusing that legacy widget in the app.

## Current station cards

The four images supplied in `assets/images/` are assigned by station ID in
`lib/features/home/data/home_station_details.dart` and declared in `pubspec.yaml`.
Cards retain their existing image crop and dark gradient behind the text.

| Station | Image asset |
| --- | --- |
| Trạm cứu hộ Revo Q.1 (`station-mobile`) | `assets/images/Tiemsua1.png` |
| Cứu hộ Minh Tuấn (`station-tuan`) | `assets/images/Tiemsua2.png` |
| Đại lý chính hãng An Phát (`station-dealer`) | `assets/images/Tiemsua3.png` |
| Tiệm sửa xe Thành Công (`station-thanh`) | `assets/images/Tiemsua4.png` |

## Legacy illustration assets

The earlier assets remain bundled; `rescue-tow.png` is the fallback for stations
without assigned image metadata.

These are illustrative station photos created with the built-in `image_gen` tool using the [imagegen skill](/Users/phamthicamthu/.codex/skills/.system/imagegen/SKILL.md). They are not photographs of the sample stations. Original generated files are retained; the app bundles copies of the selected outputs.

## assets/images/rescue-tow.png

Mode: built-in tool. Use case: photorealistic-natural.

Final prompt:

> Use case: photorealistic-natural. Asset type: illustrative rescue station card photo in the Revo mobile app. Primary request: a professional flatbed recovery truck carrying a dark compact car, parked outside a clean urban vehicle rescue depot in Ho Chi Minh City. Style: premium editorial automotive photography, monochrome black white and gray, natural soft daylight, realistic tow truck proportions. Composition: portrait 4:5, three-quarter front view, tow truck centered in the upper two-thirds, unobtrusive dark pavement in lower quarter suitable for a UI text overlay. No text, logos, brand names, watermarks, badges, UI elements or borders. A single coherent photo, no montage.

## assets/images/rescue-team.png

Mode: built-in tool. Use case: photorealistic-natural.

Final prompt:

> Use case: photorealistic-natural. Asset type: illustrative rescue station card photo for the Revo mobile app. Primary request: two professional Vietnamese roadside mechanics in dark workwear preparing tools beside a motorcycle and a compact road assistance van at a tidy city workshop. Style: premium realistic editorial photo, black white gray monochrome, soft daylight, calm professional mood. Composition: portrait 4:5, people and motorcycle centered in the upper two-thirds, dark pavement at bottom for a UI text overlay. No text, logos, brand names, watermarks, badges, UI or borders. Single coherent photograph.

## assets/images/rescue-garage.png

Mode: built-in tool. Use case: photorealistic-natural.

Final prompt:

> Use case: photorealistic-natural. Asset type: illustrative rescue station card photo for the Revo mobile app. Primary request: a modern organized Vietnamese motorcycle repair station, technician inspecting the front wheel of a scooter, metal workshop door and clean tool bench in the background. Style: premium editorial photography, realistic black white gray monochrome, soft daylight, professional and trustworthy. Composition: portrait 4:5, scooter and mechanic in upper two-thirds, dark floor at bottom for a UI text overlay. No text, logos, brand names, watermarks, UI elements, badges or borders. Single photo.
