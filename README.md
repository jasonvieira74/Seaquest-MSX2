# Seaquest MSX2 — V40 FINAL

V40 freezes the complete V39 game and corrects the last identified mismatch:
the protagonist explosion's perceived strength on the MSX PSG.

- Cartwright's duration, alternating divisors, POLY5/POLY9 character and audio
  priority remain exactly as validated in V39;
- the first source `AUDV=6` phase now uses AY level 12, compensating the PSG's
  logarithmic DAC and the lower average energy of tone/noise gating;
- the second source fade no longer copies linear TIA values directly into the
  logarithmic AY register: a 15-entry perceptual table retains the violent
  attack and produces a long, audible decay instead of collapsing early;
- no music, gameplay, collision, score, difficulty or two-player code changed;
- the ROM is emitted as `build/seaquest-v40-final-msx2.rom`.

V39 retained:

V39 preserves the validated V38 game and addresses the front-end and audio
feedback found during extended play:

- after both players are out, the trigger returns to the title instead of
  silently restarting the previous mode;
- the held trigger is latched until release, so the title cannot immediately
  start `1 PLAYER`; every new match can again select one or two players;
- the protagonist explosion restores Cartwright's 23-step timer at 15 Hz,
  lasting about 92 video frames rather than the compressed 23-frame V38 sound;
- its first phase combines the calibrated divide-by-6 tone with POLY5-style
  texture, and the second uses the existing POLY9 gate plus low AY noise;
- the detected MSX-MUSIC title cue is a compact three-channel adaptation of
  the supplied `YELLOW_FM.BAS`: 112 BPM, its B/C pickup, refrain contour,
  lead, harmony and bass; machines without FM retain the V38 PSG fallback;
- the ROM is emitted as `build/seaquest-v39-msx2.rom`.

V38 retained:

V38 keeps the validated V37 front end and implements the original alternating
two-player model from Steve Cartwright's 1983 source:

- `2 PLAYERS` now starts from the title screen;
- turns alternate only after a completed protagonist death;
- the exact seven source-owned fields move with the player: three score bytes,
  reserve submarines, level, difficulty and rescued divers;
- the waiting player starts with four internal reserves, so the first handoff
  consumes one and displays the original three;
- a player with no remaining reserve is skipped, allowing the survivor to
  continue until both players are exhausted;
- player 1 uses yellow score/submarine art and player 2 uses cyan, matching the
  original color distinction;
- cursor/space work for either player, while physical joystick ports 1 and 2
  follow the active player number;
- crossing 50,000 points once per player starts a non-blocking, blinking
  `WELCOME TO SUB CLUB` sky banner for exactly 600 frames (10 seconds at 60 Hz);
- the banner uses SCREEN 5 bitmap text and consumes no sprite slots;
- the ROM is emitted as `build/seaquest-v38-msx2.rom`.

V37 retained:

V37 freezes the approved V36 gameplay and adds an isolated 60 Hz front end:

- a full-screen SCREEN 5 `SEAQUEST` logo, animated water lip and a large
  two-layer yellow submarine built without consuming gameplay sprite slots;
- a one/two-player menu in which `1 PLAYER` starts the complete game and
  `2 PLAYERS  V38` is selectable but explicitly identified as the next phase;
- a twelve-band transition into a freshly initialized V36 game state;
- a short original YM2413 sea fanfare when the internal `APRLOPLL` signature
  is found by scanning the MSX slot tree, with an AY channel-C fallback;
- no transcription of *Yellow Submarine* or other third-party melody;
- the compact title data shares the initialization page with the engine, while
  the 32 KiB Normal ROM reserves its second half for the V38 two-player state;
- the ROM is emitted as `build/seaquest-v37-msx2.rom`.

V36 retained:

V36 corrects the two oxygen phases directly from Cartwright's source and makes
the approved shark sound survive a simultaneous player shot:

- remaining-oxygen discharge uses the source's dual `AUDC=12` pure tones with
  the hardware-derived divide-by-6 AY periods already approved for the shark;
- oxygen refill uses the source's dual `AUDC=8` POLY9 paths, represented by two
  independently calibrated tone gates mixed with the AY's lowest noise clock;
- refill period is `(AUDF+1) * 3.5625`, derived from the TIA and AY clocks;
- shark volume remains 4 in isolation and rises only to 6 while a new torpedo
  effect overlaps it, compensating the AY's logarithmic channel balance;
- V35's approved torpedo texture and enemy-submarine sound are unchanged;
- the ROM is emitted as `build/seaquest-v36-msx2.rom`.

Automated openMSX validation confirmed dual calibrated discharge periods,
dual POLY9-gated refill periods, overlap-only shark volume 6, and the exact
expected AY mixer masks. Patrol motion during refill plus the complete V31
reversal/blink regression remained unchanged.

V35 retained:

## V35 TIA poly5 torpedo texture

V35 corrects the remaining timbre mismatch in the player's shot while retaining
V34's approved pitch calibration:

- Cartwright's torpedo uses TIA `AUDC=15` (`POLY5_DIV3`), whose output is
  irregular rather than a clean square wave;
- the calibrated AY tone is now gated with the AY's lowest noise clock, adding
  the missing roughness while retaining the original `AUDF` sweep and volume;
- the change is confined to the player torpedo; shark and enemy-submarine hit
  sounds remain exactly on their approved V34 paths;
- MSX-MUSIC is not required: YM2413 feedback/rhythm noise is less structurally
  similar to the TIA polynomial and would exclude baseline MSX2 machines unless
  paired with a detection/fallback layer;
- the ROM is emitted as `build/seaquest-v35-msx2.rom`.

Automated openMSX validation confirmed the calibrated torpedo envelope with AY
tone+noise mixer value 54, while shark tone-only value 61 and enemy-submarine
noise value 47 remained unchanged. The V31 reversal/blink regression also
passed without gameplay changes.

V34 retained:

## V34 TIA div-6 pitch calibration

V34 is an isolated pitch correction based on the two original TIA control
modes identified in the 1983 source:

- the player's torpedo (`AUDC0=15`) and shark destruction (`AUDC1=12`) now use
  the TIA divide-by-6 stage when translated to AY tone periods;
- the hardware-derived MSX period is `(AUDF+1) * 21.375`, replacing V33's
  provisional `(AUDF+1) * 4` mapping for only these two effects;
- their source counters, pitch direction, envelope, volume and duration are
  unchanged;
- enemy-submarine destruction remains on the approved AY noise path, untouched;
- pickup, oxygen, protagonist death, reward/refill and keyboard-click behavior
  remain byte-for-byte equivalent to V33;
- the ROM is emitted as `build/seaquest-v34-msx2.rom`.

Automated openMSX validation measured the calibrated torpedo period at 363
(`AUDF=16`) and shark-hit period at 192 (`AUDF=8`), retained the original
volume envelope and confirmed that enemy-submarine destruction still uses the
unchanged noise mixer. Collision, reversal and six-diver blink regressions also
passed.

V33 retained:

## V33 source-priority PSG and credits

V33 retains the validated V32 gameplay and adds the first complete audio pass,
translated from Steve Cartwright's Atari routines rather than invented events:

- AY channel A follows the original TIA channel 0 priority: protagonist death,
  six-diver reward/refill, then the player's torpedo;
- AY channel B follows TIA channel 1: swimmer pickup, oxygen warning, shark hit,
  then enemy-submarine hit;
- source counters, divider changes, four-bit volume behavior and silences are
  preserved, including the initially silent enemy-submarine impact sample;
- no sound was added to events that are silent in the 1983 source, including
  enemy-torpedo launch;
- the BIOS key click remains disabled without muting any PSG channel;
- the black footer now carries `(c) Activision 1983 / @filesguy 2026.` in a
  compact 5x7 SCREEN 5 bitmap;
- the source header credits `1983 Steve Cartwright / 2026 Jason Vieira`;
- the ROM is emitted as `build/seaquest-v33-msx2.rom`.

Automated openMSX 21.0 validation passed every PSG priority and envelope sample,
the disabled BIOS click, all seven signature rows, and game-over silence with
`failures=0`. The V26–V31 regression suite also retained the validated collision,
life, difficulty, patrol, swimmer-priority, wrapped-spawn and reversal behavior.

V32 retained:

## V32 silent BIOS keyboard input

V32 is an intentionally isolated input/audio checkpoint:

- `CLIKSW` (`$F3DB`) is cleared before interrupts are enabled, reproducing
  BASIC's `KEY CLICK OFF` behavior for cursor and trigger-key input;
- the flag is asserted again by `InitState`, so a game-over restart cannot
  restore the BIOS click;
- no PSG channel is muted globally, preserving all three channels for V33;
- gameplay, collision, difficulty, swimmer direction and V31 HUD blinking are
  byte-for-byte behaviorally unchanged;
- the ROM is emitted as `build/seaquest-v32-msx2.rom`.

V31 retained:

## V31 source diver reversal and rescue blink

V31 restores the source-owned swimmer direction identified in the Atari audit
and adds the requested six-rescue HUD signal without changing V30's stable
collision geometry or wrapped formation spacing:

- Cartwright's three-round LFSR now advances every eight 60 Hz frames, including
  play, death and reward states, rather than advancing on formation reentry;
- a new formation samples the current seed exactly as `SpawnNewObstacle` does,
  so the frame on which the last shark dies determines whether the replacement
  formation keeps or reverses direction;
- an active swimmer keeps its X position and state but reads direction from its
  shark lane every frame, reproducing the occasional visible reversal after the
  last shark in a formation is destroyed;
- every successful player-torpedo hit clears that lane's accelerated swimmer
  state; a surviving shark can restore it on the next opaque-pixel contact;
- the sixth pickup latches a signal in which all six HUD swimmers alternate
  every 16 frames between their existing near-black color and the exact gray
  of the HUD foundation;
- the latch clears immediately when the protagonist first reaches the surface
  (including with a full oxygen tank), or when a death begins before delivery;
- the ROM is emitted as `build/seaquest-v31-msx2.rom`.

V30 retained:

## V30 wrapped spawn spacing

V30 fixes the shark/swimmer edge overlap identified during live V29 play by
preserving the Atari 2600's unsigned eight-bit wrap when formation coordinates
are mapped into the 240-pixel MSX sea:

- Cartwright's right-moving start at source `168` is not a visible right-edge
  coordinate: it advances through `255` and wraps to `0`; its effective signed
  origin is therefore `-88`, mapped to MSX logical `-132`;
- the left-moving source start `-41` is stored as unsigned `215`, mapped to MSX
  logical `322` rather than the previous `252`;
- swimmers retain their source entry sentinels at logical `0` and `239`, which
  restores initial leads of 132 and 83 MSX pixels instead of 62 and 13;
- because the swimmer travels at half formation speed before contact, the
  shark now catches it around logical x=132 or x=156, well inside the sea, as
  in the source model;
- the post-contact synchronized motion, pixel collision, sprite priority,
  formation masks and difficulty progression are unchanged;
- the ROM is emitted as `build/seaquest-v30-msx2.rom`.

V29 retained:

V29 corrects the three presentation/timing points observed in the live V28
test without changing collision, formation or difficulty state:

- the independent surface patrol now keeps moving during `reward_state=3`, the
  final oxygen-refill phase of the six-diver sequence; it remains frozen during
  the preceding oxygen-to-score and diver-award phases, exactly following
  Cartwright's `GS_INCREMENT_OXYGEN` route;
- the patrol uses a dedicated MSX2 gray at RGB `5,5,5`, the closest palette
  step to the NTSC reference `BLACK+9`, instead of sharing the darker HUD gray;
- the four swimmer SAT entries now precede all twelve lane-enemy entries, so
  the swimmer's white pixels remain in front when a shark touches it;
- the priority change follows SeaQuestJs' enemy-then-diver canvas order and is
  visual only: opaque-pixel collision, coordinates and synchronized movement
  are unchanged;
- the ROM is emitted as `build/seaquest-v29-msx2.rom`.

V28 retained:

V28 removes the remaining shark/swimmer overlap drift and completes the next
source-defined difficulty tier:

- the shark/diver latch is sampled from the previously rendered state before
  either entity moves, matching the TIA collision-consumption order;
- collision compares the opaque pixels of the current animated shark and
  swimmer frames at their actual vertical rows, replacing the six-pixel
  bounding-core approximation;
- after contact, a swimmer receives the exact integer displacement already
  calculated for its parent lane on that frame; it no longer owns a second
  fractional phase that can oscillate into the shark;
- the four lane step counts remain independent diagnostics, while the original
  speed and formation formulas are unchanged;
- Cartwright's independent surface patrol submarine now activates at
  `currentLevel >= 2`, always faces and travels left, and reuses the original
  eight-pixel submarine animation in dark gray;
- its original 8-bit coordinate wraps from `0` to `255`, stays off-screen until
  it drops below Atari `XMAX=160`, then maps to the 240-pixel MSX playfield;
- levels 2 through 4 move the patrol one source pixel every four frames; level
  5 and later move it every two frames, preserving the effective source table;
- patrol contact uses exact protagonist/enemy-sub pixels, kills immediately as
  the original P0/P1 latch does, and records death reason 4;
- the patrol cannot be shot, is removed during player destruction and remains
  frozen during the six-diver reward sequence;
- the ROM is emitted as `build/seaquest-v28-msx2.rom`.

Automated validation covers all eight formation stages
`1,1,3,3,5,5,7,7`, long-running shark/swimmer relative-position stability,
patrol absence at level 1, its two source cadences at levels 2 and 5, its SAT
position and animation, and an opaque-pixel surface collision. The complete V27
reserve, 10,000-point extra-life and game-over sequence is also rerun unchanged.

V27 retained:

V27 removes the remaining swimmer/formation glitch and advances to the next
source-defined gameplay system without changing the stable V26 collision model:

- a left-moving swimmer now owns the scaled `XMAX=239` entry state, matching
  the 2600 sentinel/reload path instead of being created at `x=231`; the MSX
  renderer keeps it hidden until all eight pixels fit inside the logical sea,
  so no sprite can leak into the black side margin;
- right-moving swimmers retain the source `x=0` entry, and both directions now
  remain active until the scaled source boundary rather than the sprite width;
- shark contact is latched before the swimmer's next movement step, so the
  catching shark cannot advance through it for a frame before full speed begins;
- the shark/swimmer latch is accepted only inside the original
  `XMIN+8..XMAX-9` gate, scaled to the 240-pixel MSX playfield;
- the player begins with three reserve submarines, displayed as bitmap icons in
  the sky without consuming scarce gameplay sprite slots;
- one reserve is consumed only after the death animation finishes; with no
  reserve remaining, the active submarine is removed and trigger restarts;
- crossing each packed-BCD 10,000-point boundary awards one reserve, capped at
  Steve Cartwright's `MAX_RESERVED_SUBS=6`;
- the ROM is emitted as `build/seaquest-v27-msx2.rom`.

Automated openMSX validation confirmed the left-entry state at `x=239` while
its SAT entry remained hidden, shark contact latched full speed before the
swimmer advanced, `009990 + 20` produced `010010` and a sixth reserve, the
first completed death consumed the last reserve, and the following death hid
both protagonist layers and entered game over.

V26 retained:

V26 recalibrates the SCREEN 5 vertical mapping without changing Cartwright's
movement, difficulty or collision rules:

- the ten-line animated surface remains at `y=58..67`;
- the four obstacle lanes move as one 23-pixel-spaced group to baselines
  `73, 96, 119, 142`;
- even at the shark's `-4` floating extreme, its first visible pixel begins at
  `y=69`, leaving a blank row below the surface animation;
- the lowest enemy-submarine source row ends at `y=154`, leaving a blank row
  before the reef;
- lane swimmers, enemy torpedoes, rendering and all vertical collision origins
  derive from those same lane constants;
- the reef moves from `y=150..153` to `y=156..159`;
- the HUD moves intact to `y=160..197`, with oxygen text, bar and rescued-diver
  sprites shifted together;
- the footer uses `y=198..211`, so no visible SCREEN 5 row is left undefined;
- the protagonist retains the original `SEAQUEST_YMAX=108`; at its lowest
  position its last opaque outline pixel is `y=152`, safely above the reef;
- speed, formations, score, oxygen, difficulty progression and the corrected
  V25.1 collision flags are unchanged;
- the ROM is emitted as `build/seaquest-v26-msx2.rom`.

Automated openMSX validation observed the top shark SAT at `y=68` (visible
pixel `69`), the lowest enemy-sub SAT at `y=141`, the lowest protagonist SAT
at `y=139`, and the rescued-diver HUD SAT at `y=182`. A lane-3 shot removed
exactly one target, a shifted lane-0 swimmer was rescued and displayed, and a
shifted lane-0 enemy torpedo retained death reason 3.

V25.1 retained:

V25.1 corrects three carry-flag leaks found after live V25 play:

- an enemy torpedo row above the protagonist now returns a definite miss
  instead of reusing the subtraction carry as a false pixel hit;
- a player torpedo still to the left of an obstacle no longer removes that
  obstacle before visible contact;
- a swimmer still to the left of a shark no longer enters its fleeing state
  before their visible cores meet;
- all three helpers now reserve carry exclusively for a confirmed overlap;
- true projectile and obstacle collisions retain their V25 behavior;
- the ROM is emitted as `build/seaquest-v25-1-msx2.rom`.

Automated openMSX validation confirmed: an enemy torpedo above the player does
not kill; a visible torpedo hit still records death cause 3; a player shot
moving away from a submarine removes no copy; a true hit removes one copy and
increments the shot counter; and a distant swimmer remains at half speed.

V25 retained:

V25 implements Cartwright's lane-owned enemy torpedoes without changing the
stable V24.1 obstacle hit geometry:

- every enemy-submarine lane owns at most one independent torpedo;
- the foremost surviving replicated submarine fires only inside the original
  central firing gate, scaled from 160 to 240 logical pixels;
- projectile speed follows `(difficulty + 16) / 16`, scaled by 1.5 for the
  wider MSX playfield with fractional motion preserved;
- projectile direction is captured from the firing formation and both visual
  orientations are strict horizontal reflections;
- the two separated four-pixel pulses reconstruct the original TIA BALL using
  the readable SeaQuestJs raster, while movement and timing remain governed by
  the Atari source;
- collision tests only those eight visible projectile pixels against opaque
  yellow protagonist pixels; the decorative outline cannot cause a death;
- an enemy torpedo hit records death cause `3` and removes that torpedo on the
  same frame;
- a completely destroyed submarine formation remains absent while its last
  torpedo is in flight, then respawns as sharks after the projectile exits;
- four extra sprite slots raise the SAT from 25 to 29 entries while retaining
  a worst-case maximum of seven sprites on any gameplay scanline;
- reward reset clears the shared torpedo/diver motion bytes exactly where the
  original clears `enemySubTorpedoOrDiverHorizPos`;
- the ROM is emitted as `build/seaquest-v25-msx2.rom`.

Automated openMSX validation confirmed right/left patterns 136/140, independent
lane motion, delayed zero-mask respawn, shark restoration and a visible-pixel
torpedo hit with death reason 3.

V24.1 retained:

V24.1 corrects the difficult enemy-submarine hits reported during live V24
play without enlarging the enemy beyond its visible source art:

- projectile Y is translated from the torpedo's actual pattern row instead of
  reusing a lane-wide approximation;
- sharks retain their seven visible source rows and their hit interval now
  follows the same vertical wave offset used for rendering;
- enemy submarines use their distinct source-art interval, rows 2 through 12,
  so shots through the visible lower hull are no longer discarded;
- space immediately above and below the sprite remains non-colliding;
- horizontal width, replicated-copy selection, score and formation state are
  unchanged;
- the ROM is emitted as `build/seaquest-v24-1-msx2.rom`.

V24 retained:

V24 implements the obstacle-type alternation defined by Steve Cartwright's
Atari source without adding a random spawn system:

- after a complete boundary crossing, each lane alternates between sharks and
  enemy submarines while retaining the source formation masks;
- destroying the complete formation rebuilds that lane as sharks, matching
  the original `SpawnNewObstacle` path;
- enemy submarines use the three original eight-pixel animation frames,
  reconstructed in top-to-bottom order with strict horizontal reflections;
- their fixed vertical position, smaller dimensions and white color remain
  distinct from the larger yellow protagonist;
- swimmers belong only to shark lanes and are removed when their parent lane
  changes to an enemy submarine;
- rendering, player collision and torpedo collision all select the same live
  obstacle type and direction;
- a torpedo removes only the struck replicated copy and awards the existing
  source-derived target value;
- enemy torpedoes are deliberately deferred to V25 instead of being invented
  in this version;
- the ROM is emitted as `build/seaquest-v24-msx2.rom`.

Automated openMSX validation confirmed shark-to-submarine alternation at the
boundary, two correctly spaced white submarine copies, per-copy destruction,
right/left pattern reflection and a destroyed submarine formation returning to
green sharks. Regression runs also retained the medium-spaced last-survivor
exit, ordinary oxygen refill and the complete timed six-diver reward sequence.

V23 retained:

This version is isolated from the earlier SCREEN 2 experiment. It establishes the
rendering and coordinate foundation approved in `docs/atari-game-map.md`.

V23 corrects the first green shark lane after observing live V22 gameplay:

- V22 rendered the first green copy from `lane_x_0`, then accidentally read
  `lane_x_1` and `lane_x_2` as its second and third copies;
- those bytes belong to independent lanes, explaining opposite-edge spawns,
  crossings, apparent horizontal inversion and visual/collision disagreement;
- lane zero now renders all three copies from `shark_x_cache_0`, exactly like
  the other three lanes;
- direction and animation pattern are shared by every copy in the formation;
- shooting a two-copy formation clears only the struck survivor bit;
- score, oxygen, rescues and progression are unchanged;
- the ROM is emitted as `build/seaquest-v23-msx2.rom`.

Automated openMSX validation placed a two-copy mask in lane zero. Before the
shot, cache positions `103,79` rendered at screen positions `111,87` with the
same pattern. After the shot, mask `3` became `2`: copy zero was hidden at
Y=211, copy one remained visible and the score increased by 20. The reverse
direction also retained 24-pixel spacing and one reflected pattern for both
copies.

V22 retained:

V22 separates Cartwright's two progression values and activates the score:

- `currentLevel` advances only after the complete six-diver reward;
- `levelDifficulty` continues to advance after an ordinary diver delivery and
  catches up to `currentLevel` after a six-diver cycle;
- target value follows `min(currentLevel + 2, 9) * 10`, starting at 20 points;
- each torpedo hit awards the current target value;
- every oxygen unit converted during the six-diver reward awards the current
  target value;
- every rewarded diver awards `50 * (currentLevel + 1)`, with the multiplier
  capped at level 19 as in the Atari source;
- score uses three packed-BCD bytes, displays six digits and saturates at
  999,990;
- the source's extra 16-frame boundary between the sixth diver and level
  advancement is preserved;
- ordinary oxygen refill still changes difficulty without changing the level;
- the ROM is emitted as `build/seaquest-v22-msx2.rom`.

Automated openMSX validation confirmed 20 points for a level-zero torpedo hit,
380 points for four converted oxygen units plus six level-zero divers, level
`0 -> 1`, difficulty `0 -> 1`, and point value `20 -> 30`. A visual capture also
verified the HUD transition from `000000` to `000020` without corruption.

Enemy-submarine patterns are intentionally not replaced with invented sharks.
Until the submarine entity exists, the active obstacle table remains the
source-derived shark masks; the full type alternation is the next milestone.

V21 retained:

V21 corrects the two regressions observed in V20:

- a formation now crosses an edge until its last surviving logical copy is
  outside the 240-pixel viewport;
- the boundary is derived from the survivor mask and the active 24/48-pixel
  spacing, so a medium-spaced third shark cannot disappear at the old fixed
  close-spacing limit;
- direction and survivor mask remain stable for the complete crossing;
- rescuing six divers now enters Cartwright's three-stage `GameProcessing`
  sequence: remaining oxygen every two frames, one diver every 16 frames, and
  oxygen refill every two frames;
- ordinary one-diver oxygen refill is unchanged;
- formations freeze during the reward and respawn from the source masks only
  after the refill completes;
- the ROM is emitted as `build/seaquest-v21-msx2.rom`.

Automated openMSX validation confirmed that mask 5 retains its third copy at
X=199 on the right crossing and X=42 on the left crossing. The six-diver test
observed states `1 -> 2 -> 3 -> 0`, divers `6 -> 4 -> 0`, and oxygen `4 -> 0 ->
64` without the former one-frame shortcut.

V20 retained:

V20 adds the source-backed swimmer relationship:

- each lane swimmer uses source states absent, active and rescued;
- formation reconstruction attempts swimmer spawn only for seed values >=80;
- swimmers enter from the edge matching the parent formation direction;
- normal swimmer speed is exactly half the formation speed;
- contact with a visible shark core activates the source speed-up state;
- fleeing swimmers match formation speed and animate twice as quickly;
- rescued lane slots stay unavailable until all four slots have been rescued;
- leaving the playfield removes the swimmer without a center respawn;
- the ROM is emitted as `build/seaquest-v20-msx2.rom`.

The ordinary oxygen implementation was measured and preserved: zero-to-full
reached 60 of 64 units after 2.25 realtime seconds in openMSX.

V19 retained:

V19 replaces the experimental circular spawning model with source-derived
formation state:

- each lane owns a signed 16-bit linear anchor, direction and survivor mask;
- copies trail the lead and never wrap independently across the screen;
- a hit clears only the struck copy until the final survivor is destroyed;
- crossing an edge preserves the surviving-copy mask;
- killing the complete formation rebuilds it from Cartwright's masks
  `1,1,3,3,5,5,7,7`;
- close and medium NUSIZ spacing scale to 24 and 48 MSX pixels;
- initial speed and difficulty increments use the source formula, scaled 1.5x;
- direction comes from the source three-round LFSR rather than arbitrary calls;
- sharks receive a 64-frame triangular floating cycle;
- successful diver delivery increments the formation difficulty;
- the ROM is emitted as `build/seaquest-v19-msx2.rom`.

Enemy-submarine alternation is deliberately not fabricated in this slice; it
remains the next source-backed entity implementation.

V18 corrections retained where compatible:

- left-moving sharks respawn only at X=232, when all eight pixels fit onscreen;
- replicated copies enter at deterministic 48-pixel intervals;
- clipped positions X=233..239 can no longer reactivate a destroyed shark;
- each entry event restores only its own copy, never the complete group;
- spawn validation covers both directions and the second replicated copy;
- the ROM is emitted as `build/seaquest-v18-msx2.rom`.

V17 corrections retained:

- collisions are calculated from the opaque pixels of the current submarine
  and shark animation frames;
- transparent areas inside the 16×16 sprite boxes cannot cause a death;
- the protagonist's decorative outline does not enlarge its collision mask;
- lane state is preserved between the three replicated shark tests;
- two consecutive frames of real pixel contact are still required;
- a 23-frame impact sequence makes the death cause visible before respawn;
- the ROM is emitted as `build/seaquest-v17-msx2.rom`.

V16.3 corrections retained:

- all three swimmer frames now use the exact top-to-bottom order from
  SeaQuestJs `sprites.js`;
- left-facing frames are strict horizontal bit reversals;
- player/shark collision uses the protagonist center point against the
  shark's three-row, six-pixel solid core;
- two-frame contact confirmation remains active;
- respawns record cause `1` for shark collision and `2` for oxygen/surface;
- automated tests distinguish safe movement, shark death and oxygen death.

V16.2 additions retained:

- player/shark contact must persist across two consecutive frames;
- a one-frame graze no longer triggers a death;
- pending collision state is cleared immediately when contact disappears;
- multiple sharks in the same frame cannot count as two confirmations;
- a rescued diver opens a protected delivery corridor above `y=23`;
- surfacing with a rescued diver cannot be converted into a lane-0 respawn;
- diver patterns again follow the SeaQuestJs convention: base art faces right,
  reflected art faces left.

V16.1 corrections retained:

- diver pattern selection now faces the actual movement direction;
- player/shark collision uses smaller visible solid cores;
- the first-lane vertical collision interval is reduced from `16..26` to
  `18..23`, with equivalent corrections on the other lanes;
- transparent sprite fringes no longer trigger a player death;
- a surfaced submarine with a rescued diver preserves its horizontal position;
- regression coverage distinguishes a near miss from a visible collision.

V16 additions retained:

- four independent diver entities, one for each enemy lane;
- lane-fixed vertical positions matching the Atari `diverArray` structure;
- half-speed horizontal swimmer movement;
- swimmers leave the screen instead of reversing unnaturally;
- inactive swimmers respawn only when their own lane reaches its entry edge;
- independent pickup/removal, leaving the other lane swimmers untouched;
- four gameplay diver sprites plus six rescued-diver HUD sprites;
- expanded 25-entry SAT shadow and state RAM relocated beyond it;
- worst-case gameplay scanline count kept at seven, below the MSX2 limit of eight.

V15.2 additions retained:

- the complete three-frame, 14-line diver reconstruction from SeaQuestJs;
- six dedicated rescued-diver sprites in the HUD scanlines;
- no runtime bitmap writes when the rescued count changes;
- relocated state RAM so the expanded 22-entry SAT shadow cannot overlap it;
- verified surface refill with a real rescued-diver count.

V15.1 corrections retained:

- vertical orientation of the in-water swimmer patterns;
- two complete kick frames in both horizontal directions;
- deterministic SCREEN 5 destination calculation for every HUD icon row;
- full black coverage of rows 192..211 below the HUD;
- removal of stray pixels and the uninitialized gray strip below the footer.

V15 additions retained:

- one animated swimmer moving at half speed and reversing at the playfield edges;
- solid-core pickup collision and a rescued count from zero to six;
- six custom bitmap diver indicators in the lower HUD, consuming no sprite slots;
- Atari surface rule: partial oxygen requires a rescued diver;
- one rescued diver consumed when oxygen becomes full;
- a six-diver bank transition, ready for the score bonus pass;
- collision rejection for sharks hidden by right-edge clipping;
- protagonist/shark AABB collision aligned to their visible solid cores;
- regression checks for pickup, visible collision, and clipped collision.

V14 additions retained:

- 64-unit oxygen state matching the Atari constant;
- depletion by one unit every 32 frames below `YMIN+7`;
- a proportional 160-pixel bitmap bar;
- low-oxygen color warning at 16 units;
- oxygen exhaustion respawn at the centered surface position;
- dynamic oxygen bar and low-oxygen warning.

V13 correction retained:

- the outline direction flag is evaluated before pattern arithmetic;
- yellow body and navy contour now select the same orientation.

V12 additions retained:

- an exclusive second sprite layer for the protagonist;
- a one-pixel near-black navy contour;
- a redesigned 14x12 yellow body inside the 16x16 cell;
- collision geometry independent from the decorative contour;
- no extra layers for sharks, torpedoes, or future divers.

V11 corrections retained:

- true modulo-240 arithmetic after 8-bit carry for every replicated shark;
- identical normalized positions in drawing and both collision paths;
- oxygen label and bar on one horizontal line;
- the lower half of the gray HUD reserved for rescued-diver icons.

V10 additions retained:

- a 240-pixel native playfield (`x=8..247`);
- formation spacing expanded from 32 to 48 pixels;
- enemy speed scaled from 6/16 to 9/16 pixel per frame;
- a true 16x14 protagonist sprite while sharks remain 8x7;
- 2-pixel horizontal player movement and recalibrated boundaries;
- a wider HUD foundation and oxygen bar.

Vertical layout retained:

- sky at `y=4..47`;
- horizon at `y=48..57`;
- gameplay sea at `y=58..149`;
- reef at `y=150..153`;
- expanded gray HUD at `y=154..191`;
- black footer at `y=192..201`;
- static placeholders for three lives, six score digits and oxygen.

V8 calibration retained:

- reference sky RGB `(88,105,249)` to MSX2 RGB `(2,3,7)`;
- reference sea RGB `(63,17,248)` to MSX2 RGB `(2,0,7)`;
- one uniform sky index, avoiding artificial bands absent from the target.

V7 refinements retained:

- solid-color sky and horizon bands without alternating pixel combs;
- a mostly uniform cobalt sea matching the visual reference;
- a narrow animated surface crest instead of ten high-contrast stripes.

V6 additions retained:

- layered SCREEN 5 sky gradient;
- the Atari reference's ten-line yellow/red/purple/cobalt horizon;
- ten animated surface scanlines using four pseudo-LFSR color phases;
- deeper cobalt gameplay water and a green reef edge.

V5 corrections retained:

- each destroyed shark returns only when its own logical copy crosses the entry edge;
- no group-wide mask reset when the formation base wraps;
- the submarine respawn remains centered, matching the Atari source.

V4 corrections retained:

- shark clipping at both viewport edges;
- torpedo alignment with the submarine's launch tube;
- direction-dependent horizontal torpedo origin;
- projectile clipping before its pixels reach the margin;
- player collision based on visible solid cores.

V3 corrections retained:

- shark orientation according to its approach direction;
- a 1.5-second safe launch window so the submarine can leave the surface;
- narrower collision boxes that ignore fringe pixels;
- a new safe window after each player collision, preventing collision loops.

V2 additions retained:

- independent collision/removal for every replicated shark;
- player/shark collision with surface respawn;
- shark art selected according to movement direction;
- torpedo vertically centered on the submarine;
- sunset horizon, animated-looking wave pattern, and reef edge.

Foundation inherited from V1:

- MSX2 cartridge ROM, 16 KiB;
- SCREEN 5 at 256×212;
- 16-color NTSC-inspired palette;
- centered 240-pixel viewport (`x=8..247`);
- four 23-line gameplay lanes (`y=58..149`);
- original 8-pixel-wide graphics placed in 16×16 sprite cells without horizontal scaling;
- three-frame player animation and horizontal reflection as separate patterns;
- joystick movement with Atari logical limits;
- one player torpedo;
- four moving three-copy obstacle formations;
- at most seven gameplay sprites on one scanline by design;
- 60 Hz frame loop using VBlank.

Not yet implemented in this vertical slice:

- reserve submarines and score-awarded extra lives;
- two-player alternation;
- PSG effects and HUD text.

Build from PowerShell:

```powershell
.\build.ps1
```

Output: `build/seaquest-v26-msx2.rom`.
