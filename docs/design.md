# Screen design

| Screen | Feature IDs | Primary action and states |
| --- | --- | --- |
| Onboarding | F-01 | See an original/Deutan example and read about the model. Start or skip and access guidance again through Home. |
| Home | F-02, F-03, F-07 | Open the camera, choose a JPEG/PNG, or explore six scenes. Show file loading and a recoverable error. |
| Simulator | F-02, F-03, F-04, F-06 | Display the source with mode chips and a strength slider. Compare the image or freeze the camera. For a camera failure, show photo and sample actions. |
| Compare | F-04, F-05, F-06 | Use a horizontal image divider with an accessible slider or place the same two images side by side. Switch layouts with mode and strength preserved. |
| Explore and Learn | F-07, F-08 | Open a scene with alt text, a barrier description and a design tip. Switch tabs to find model notes and references. |

Material 3 uses blue seed #2563EB, system light/dark, and a dark navy onboarding/home hero. Content uses a scrollable 680 px maximum width, 20 px side gutters, and vertically wrapping choice chips. Buttons are at least 48 px tall. The selected chip uses labels and a check mark. Compare labels and the light/dark separator identify each side without color. The scene library uses two columns when at least 560 px is available and preserves the full image aspect ratio. Only the photo, illustration or camera preview receives the transform. Six 900 × 560 illustrations are labeled in both languages and included offline.
