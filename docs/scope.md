# Scope and implementation decisions

My Eyes serves students, educators, and people designing color-dependent materials. The main journey is to open one source, explore differences using the five modes, compare the original and transformed views, and read a practical accessibility tip. The [English plan](PLAN.md) defines the eight P0 feature IDs, acceptance criteria, and release gates.

Flutter is the implementation stack. The native app targets Android and iOS. The web target provides a way to exercise file and sample flows without a phone. The application needs no network for the eight core features on a supported phone. Reference links open a browser only when the user activates them.

| Area | Implementation |
| --- | --- |
| Source | A disposable Flutter image or an active rear-camera controller. A frozen comparison uses a JPEG capture decoded into one immutable image. |
| Settings | In-memory vision mode, strength, and compare divider. System controls app theme and supported locale. Local preferences record onboarding completion. |
| Simulation | Normalize encoded RGB into linear values, apply row-major Machado matrices interpolated at adjacent levels, then encode back to sRGB. Grayscale uses linear luminance. |
| Camera | Flutter camera texture plus an Impeller image-filter shader. The platform handles sensor rotation and camera color conversion. Cross-device color management and target performance require reference hardware. |
| Import | JPEG and PNG preview limits are 24 MiB, 32 MP before downscaling, and 2048 pixels on the long edge after resizing. EXIF rotation is baked in. Non-sRGB/wide-gamut consistency is pending device validation. |
| Education | Six original illustrations and bilingual descriptions. Reach external references from the Learn tab. |
| Future plan | Export, challenges, palette analysis, and video remain the P1/P2 backlog. |

Source for the matrix coefficients and interpolation method is [the authors' UFRGS reference table](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html), accompanying Machado, Oliveira and Fernandes, 2009, [DOI 10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113). The source tables are cited in the Dart file. The illustrations in the bundle were drawn for this demo.

The 30 FPS live preview, 100 ms mode-switch budget, hardware coverage, and educational pilot metrics from the plan remain release targets. The sample scenes are illustrations of color-dependent situations and descriptions present the simulation as an educational approximation.
