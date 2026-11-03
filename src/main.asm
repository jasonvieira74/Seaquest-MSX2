; Seaquest MSX2 V40 FINAL - perceptually calibrated protagonist explosion
; Target: MSX2, 60 Hz, sjasmplus
;
; Original design and programming: 1983 Steve Cartwright
; MSX2 reconstruction:            2026 Jason Vieira

        org $4000

        db "AB"
        dw Init
        dw 0,0,0,0,0,0

; BIOS
CHGMOD          equ $005F
RDSLT           equ $000C
GTSTCK          equ $00D5
GTTRIG          equ $00D8
LDIRVM          equ $005C
FILVRM          equ $0056
WRTVRM          equ $004D
WRTVDP          equ $0047
GRPPRT          equ $008D
WRTPSG          equ $0093
RDPSG           equ $0096

; BIOS work area
RG1SAV          equ $F3E0
RG7SAV          equ $F3E6
BDRCLR          equ $F3EB
FORCLR          equ $F3E9
BAKCLR          equ $F3EA
CLIKSW          equ $F3DB
GRPACX          equ $FCB7
GRPACY          equ $FCB9
EXPTBL          equ $FCC1

; Video layout
SCREEN5_MODE            equ 5
SPRITE_SIZE_16          equ %00000010
SPRITE_COLOR_TABLE      equ $7400
SPRITE_ATTR_TABLE       equ $7600
SPRITE_PATTERN_TABLE    equ $7800
VISIBLE_VRAM_BYTES      equ 128*212
VIEWPORT_X              equ 8
VIEWPORT_BYTES_X        equ VIEWPORT_X/2
VIEWPORT_WIDTH_BYTES    equ 240/2
; Y=216 terminates the whole SAT in 212-line mode. Use 211 so this sprite starts
; at scanline 212 (off-screen) without hiding every later sprite entry.
SPRITE_HIDE_Y           equ 211

; Logical Atari geometry
X_MIN                   equ 0
X_MAX                   equ 239
PLAYER_X_MIN            equ 0
PLAYER_X_MAX            equ 224
PLAYER_WIDTH            equ 16
ENEMY_WIDTH             equ 8
; The 2600 positions are unsigned bytes. A right-moving formation starts at
; 168 and wraps through 255 to 0, so its effective logical origin is -88.
; A left-moving formation starts at -41, stored as unsigned 215. Scale those
; effective coordinates, not the source literals, into the 240-pixel sea.
FORMATION_LEFT_START    equ -132 ; (168-256) * 3/2
FORMATION_RIGHT_START   equ 322  ; floor(215 * 3/2)
SHARK_CLOSE_SPACING     equ 24   ; Atari 16-pixel NUSIZ spacing scaled 1.5x
SHARK_MED_SPACING       equ 48   ; Atari 32-pixel NUSIZ spacing scaled 1.5x
PLAYER_Y_MIN            equ 13
PLAYER_Y_MAX            equ 108
PLAYER_SCREEN_Y_OFFSET  equ 32
MAX_OXYGEN_VALUE        equ 64
MAX_RESERVED_SUBS       equ 6
OXYGEN_DIVE_THRESHOLD   equ PLAYER_Y_MIN+7
SURFACE_SAFE_Y          equ PLAYER_Y_MIN+11
SEA_SURFACE_Y           equ 58
SEA_SURFACE_ROWS        equ 10
SEA_PLAYFIELD_Y         equ SEA_SURFACE_Y+SEA_SURFACE_ROWS
REEF_TOP_Y              equ 156
HUD_TOP_Y               equ 160
FOOTER_TOP_Y            equ 198
HUD_OXYGEN_Y            equ HUD_TOP_Y+9
HUD_OXYGEN_BAR_Y        equ HUD_TOP_Y+11
HUD_DIVER_Y             equ HUD_TOP_Y+23
LANE_SPACING            equ 23
; One blank row follows the ten-line surface animation before the highest
; possible shark pixel. The fourth lane's source art ends above the reef.
LANE0_Y                 equ SEA_PLAYFIELD_Y+5
LANE1_Y                 equ LANE0_Y+LANE_SPACING
LANE2_Y                 equ LANE1_Y+LANE_SPACING
LANE3_Y                 equ LANE2_Y+LANE_SPACING
DIVER_Y_OFFSET          equ -3
DIVER0_LOGICAL_Y        equ LANE0_Y+DIVER_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
DIVER1_LOGICAL_Y        equ LANE1_Y+DIVER_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
DIVER2_LOGICAL_Y        equ LANE2_Y+DIVER_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
DIVER3_LOGICAL_Y        equ LANE3_Y+DIVER_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
TORPEDO_PATTERN_ROW     equ 6
SHARK_VISIBLE_ROWS      equ 7    ; source art rows 0..6
ENEMY_SUB_FIRST_ROW     equ 2
ENEMY_SUB_VISIBLE_ROWS  equ 11   ; source art rows 2..12
ENEMY_TORPEDO_Y_OFFSET  equ 5    ; SeaQuestJs reconstruction of the TIA BALL rows
ENEMY_TORPEDO_MIN_X     equ 59   ; scaled original firing gate: 39 * 1.5
ENEMY_TORPEDO_MAX_X     equ 190  ; exclusive; original upper gate is 126
DIVER_INTERACTION_MIN_X equ 12   ; source XMIN+8, scaled from 160 to 240
DIVER_INTERACTION_MAX_X equ 227  ; exclusive source XMAX-9 gate, scaled
PATROL_SUB_LOGICAL_Y    equ PLAYER_Y_MIN ; shares the surfaced-player band
LANE0_TORPEDO_BASE_Y    equ LANE0_Y-PLAYER_SCREEN_Y_OFFSET-TORPEDO_PATTERN_ROW
LANE1_TORPEDO_BASE_Y    equ LANE1_Y-PLAYER_SCREEN_Y_OFFSET-TORPEDO_PATTERN_ROW
LANE2_TORPEDO_BASE_Y    equ LANE2_Y-PLAYER_SCREEN_Y_OFFSET-TORPEDO_PATTERN_ROW
LANE3_TORPEDO_BASE_Y    equ LANE3_Y-PLAYER_SCREEN_Y_OFFSET-TORPEDO_PATTERN_ROW

; Only the protagonist uses two layers; enemies retain one sprite each.
SPR_PLAYER_OUTLINE      equ 0
SPR_PLAYER              equ 1
SPR_TORPEDO             equ 2
; Lower SAT indexes have priority on MSX2. Keep the four swimmers ahead of
; every lane copy so their white pixels remain readable when a shark catches
; them, matching SeaQuestJs' enemy-then-diver draw order.
SPR_DIVER0              equ 3
SPR_DIVER1              equ 4
SPR_DIVER2              equ 5
SPR_DIVER3              equ 6
SPR_LANE0               equ 7
SPR_LANE1               equ 10
SPR_LANE2               equ 13
SPR_LANE3               equ 16
SPR_HUD_DIVER0          equ 19
SPR_ENEMY_TORPEDO0      equ 25
SPR_ENEMY_TORPEDO1      equ 26
SPR_ENEMY_TORPEDO2      equ 27
SPR_ENEMY_TORPEDO3      equ 28
SPR_PATROL_SUB          equ 29
SPRITE_COUNT            equ 30
SPRITE_ATTR_BYTES       equ SPRITE_COUNT*4

; Pattern numbers (one 16x16 sprite consumes four 8-byte patterns)
PAT_SUB_R0              equ 0
PAT_SUB_R1              equ 4
PAT_SUB_R2              equ 8
PAT_SUB_L0              equ 12
PAT_SUB_L1              equ 16
PAT_SUB_L2              equ 20
PAT_TORPEDO_R           equ 24
PAT_TORPEDO_L           equ 28
PAT_SHARK_R0            equ 32
PAT_SHARK_R1            equ 36
PAT_SHARK_L0            equ 40
PAT_SHARK_L1            equ 44
PAT_OUTLINE_R0          equ 48
PAT_OUTLINE_R1          equ 52
PAT_OUTLINE_R2          equ 56
PAT_OUTLINE_L0          equ 60
PAT_OUTLINE_L1          equ 64
PAT_OUTLINE_L2          equ 68
PAT_DIVER_R0            equ 72
PAT_DIVER_R1            equ 76
PAT_DIVER_R2            equ 80
PAT_DIVER_L0            equ 84
PAT_DIVER_L1            equ 88
PAT_DIVER_L2            equ 92
PAT_HUD_DIVER           equ 96
PAT_EXPLOSION_0         equ 100
PAT_EXPLOSION_1         equ 104
PAT_EXPLOSION_2         equ 108
PAT_ENEMY_SUB_R0        equ 112
PAT_ENEMY_SUB_R1        equ 116
PAT_ENEMY_SUB_R2        equ 120
PAT_ENEMY_SUB_L0        equ 124
PAT_ENEMY_SUB_L1        equ 128
PAT_ENEMY_SUB_L2        equ 132
PAT_ENEMY_TORPEDO_R     equ 136
PAT_ENEMY_TORPEDO_L     equ 140

; Palette indexes
PAL_BLACK               equ 0
PAL_SKY                 equ 1
PAL_SEA                 equ 2
PAL_HORIZON             equ 3
PAL_FLOOR               equ 4
PAL_WHITE               equ 5
PAL_YELLOW              equ 6
PAL_CYAN                equ 7
PAL_GREEN               equ 8
PAL_BROWN               equ 9
PAL_PURPLE              equ 10
PAL_RED                 equ 11
PAL_BLUE                equ 12
PAL_DARK_GRAY           equ 13
PAL_PATROL_GRAY         equ 14
PAL_DYNAMIC             equ 15
PAL_OUTLINE             equ 15

; RAM in page 3
RAM_BASE                equ $C000
player_x                equ RAM_BASE+0
player_y                equ RAM_BASE+1
player_facing           equ RAM_BASE+2 ; 0 right, 1 left
player_anim             equ RAM_BASE+3
anim_tick               equ RAM_BASE+4
torpedo_active          equ RAM_BASE+5
torpedo_x               equ RAM_BASE+6
torpedo_y               equ RAM_BASE+7
torpedo_dir             equ RAM_BASE+8
lane_x_0                equ RAM_BASE+9
lane_x_1                equ RAM_BASE+10
lane_x_2                equ RAM_BASE+11
lane_x_3                equ RAM_BASE+12
lane_dir_0              equ RAM_BASE+13
lane_dir_1              equ RAM_BASE+14
lane_dir_2              equ RAM_BASE+15
lane_dir_3              equ RAM_BASE+16
lane_frac_0             equ RAM_BASE+17
lane_frac_1             equ RAM_BASE+18
lane_frac_2             equ RAM_BASE+19
lane_frac_3             equ RAM_BASE+20
frame_counter           equ RAM_BASE+21
bg_y                    equ RAM_BASE+22
bg_count                equ RAM_BASE+23
bg_color                equ RAM_BASE+24
lane_mask_0             equ RAM_BASE+25
lane_mask_1             equ RAM_BASE+26
lane_mask_2             equ RAM_BASE+27
lane_mask_3             equ RAM_BASE+28
draw_lane_dir           equ RAM_BASE+29
draw_lane_mask          equ RAM_BASE+30
draw_lane_bit           equ RAM_BASE+31
player_grace            equ RAM_BASE+160
lane_moved              equ RAM_BASE+161
wave_phase              equ RAM_BASE+162
wave_draw_y             equ RAM_BASE+163
wave_draw_count         equ RAM_BASE+164
hud_rect_x              equ RAM_BASE+165
hud_rect_width          equ RAM_BASE+166
oxygen_value            equ RAM_BASE+167
retrieved_divers        equ RAM_BASE+168
hud_diver_count         equ RAM_BASE+169
hud_diver_x             equ RAM_BASE+170
hud_diver_rows          equ RAM_BASE+171
; Four-byte lane-owned structs: active, X, direction, half-speed fraction.
diver_state_0           equ RAM_BASE+176
diver_state_1           equ RAM_BASE+180
diver_state_2           equ RAM_BASE+184
diver_state_3           equ RAM_BASE+188
collision_confirm       equ RAM_BASE+192
collision_seen          equ RAM_BASE+193
death_reason            equ RAM_BASE+194 ; 0 none, 1 obstacle, 2 oxygen, 3 enemy torpedo
death_timer             equ RAM_BASE+195 ; visible destruction frames
SAT_SHADOW              equ RAM_BASE+32
debug_marker            equ RAM_BASE+200
collision_shark_y       equ RAM_BASE+208
collision_shark_dir     equ RAM_BASE+209
pixel_shark_x           equ RAM_BASE+210
pixel_player_row        equ RAM_BASE+211
pixel_shark_row         equ RAM_BASE+212
pixel_rows              equ RAM_BASE+213
pixel_shark_bits        equ RAM_BASE+214
pixel_global_x          equ RAM_BASE+215
pixel_bit_count         equ RAM_BASE+216
pixel_local_x           equ RAM_BASE+217
formation_anchor_0      equ RAM_BASE+$100 ; four signed 16-bit anchors
formation_anchor_1      equ RAM_BASE+$102
formation_anchor_2      equ RAM_BASE+$104
formation_anchor_3      equ RAM_BASE+$106
lane_visible_0          equ RAM_BASE+$108
lane_visible_1          equ RAM_BASE+$109
lane_visible_2          equ RAM_BASE+$10A
lane_visible_3          equ RAM_BASE+$10B
shark_x_cache_0         equ RAM_BASE+$10C ; three X values per lane
shark_x_cache_1         equ RAM_BASE+$10F
shark_x_cache_2         equ RAM_BASE+$112
shark_x_cache_3         equ RAM_BASE+$115
game_difficulty         equ RAM_BASE+$118
formation_random_seed   equ RAM_BASE+$119
shark_float             equ RAM_BASE+$11A
build_alive_mask        equ RAM_BASE+$11B
build_visible_mask      equ RAM_BASE+$11C
build_direction         equ RAM_BASE+$11D
build_spacing           equ RAM_BASE+$11E
diver_fast_0            equ RAM_BASE+$120
diver_fast_1            equ RAM_BASE+$121
diver_fast_2            equ RAM_BASE+$122
diver_fast_3            equ RAM_BASE+$123
lane_reset_0            equ RAM_BASE+$124
lane_reset_1            equ RAM_BASE+$125
lane_reset_2            equ RAM_BASE+$126
lane_reset_3            equ RAM_BASE+$127
interaction_diver_x     equ RAM_BASE+$128
interaction_diver_y     equ RAM_BASE+$129
interaction_shark_y     equ RAM_BASE+$12A
draw_diver_fast         equ RAM_BASE+$12B
reward_state            equ RAM_BASE+$12C ; 0 play, 1 oxygen, 2 divers, 3 refill
current_level           equ RAM_BASE+$12D
score_bcd_high          equ RAM_BASE+$12E ; hundred-thousands / ten-thousands
score_bcd_mid           equ RAM_BASE+$12F ; thousands / hundreds
score_bcd_low           equ RAM_BASE+$130 ; tens / ones
current_point_value     equ RAM_BASE+$131 ; packed BCD, $20 through $90
lane_type_0             equ RAM_BASE+$132 ; 0 shark, 1 enemy submarine
lane_type_1             equ RAM_BASE+$133
lane_type_2             equ RAM_BASE+$134
lane_type_3             equ RAM_BASE+$135
formation_edge_resets   equ RAM_BASE+$136 ; invisible diagnostics
formation_kill_resets   equ RAM_BASE+$137
formation_shot_count    equ RAM_BASE+$138
draw_lane_type          equ RAM_BASE+$139
collision_obstacle_type equ RAM_BASE+$13A
enemy_torpedo_spawns    equ RAM_BASE+$13B ; invisible diagnostics
enemy_torpedo_hits      equ RAM_BASE+$13C
reserve_subs            equ RAM_BASE+$13D
game_over               equ RAM_BASE+$13E
extra_life_awards       equ RAM_BASE+$13F ; invisible diagnostics
hud_life_count          equ RAM_BASE+$140
hud_life_x              equ RAM_BASE+$141
hud_life_src            equ RAM_BASE+$142 ; two-byte explicit ROM row pointer
lane_step_0             equ RAM_BASE+$144 ; actual integer pixels moved this frame
lane_step_1             equ RAM_BASE+$145
lane_step_2             equ RAM_BASE+$146
lane_step_3             equ RAM_BASE+$147
active_lane_step        equ RAM_BASE+$148
interaction_shark_dir   equ RAM_BASE+$149
patrol_source_x         equ RAM_BASE+$14A ; original 0..255 Atari coordinate
patrol_screen_x         equ RAM_BASE+$14B ; scaled 0..239 logical coordinate
patrol_moves            equ RAM_BASE+$14C ; invisible diagnostics
patrol_hits             equ RAM_BASE+$14D
patrol_visible          equ RAM_BASE+$14E
hud_diver_blink_color   equ RAM_BASE+$14F ; applied MSX2 color-table value, $FF forces refresh
hud_diver_blink_active  equ RAM_BASE+$150 ; latched by sixth pickup, cleared by surface/death
sfx_pickup_counter      equ RAM_BASE+$151 ; source pickupDiverSoundValue
sfx_shark_hit_counter   equ RAM_BASE+$152 ; source shootingKillerSharkSoundValue
sfx_sub_hit_counter     equ RAM_BASE+$153 ; source shootingEnemySubSoundValue
sfx_torpedo_counter     equ RAM_BASE+$154 ; source seaquestTorpedoSoundValues
sfx_reward_counter      equ RAM_BASE+$155 ; source rewardSoundValues alias
psg_mixer_shadow        equ RAM_BASE+$156
psg_value               equ RAM_BASE+$157
psg_last_volume_a       equ RAM_BASE+$158 ; validation mirror of AY register 8
psg_last_volume_b       equ RAM_BASE+$159 ; validation mirror of AY register 9
psg_last_mixer          equ RAM_BASE+$15A ; validation mirror of AY register 7 low bits
psg_last_period_a_low   equ RAM_BASE+$15B ; V34 pitch-validation mirrors
psg_last_period_a_high  equ RAM_BASE+$15C
psg_last_period_b_low   equ RAM_BASE+$15D
psg_last_period_b_high  equ RAM_BASE+$15E
title_active            equ RAM_BASE+$15F ; nonzero while the front end owns the frame
title_selection         equ RAM_BASE+$160 ; 0 one player, 1 two players
title_move_latch        equ RAM_BASE+$161
title_trigger_latch     equ RAM_BASE+$162
title_frame             equ RAM_BASE+$163
title_wave_phase        equ RAM_BASE+$164
title_fade              equ RAM_BASE+$165
game_mode               equ RAM_BASE+$166 ; 1 or 2 players
fm_available            equ RAM_BASE+$167 ; internal APRLOPLL signature detected
fm_probe_slot           equ RAM_BASE+$168
fm_probe_value          equ RAM_BASE+$169
fm_primary              equ RAM_BASE+$16A
fm_secondary            equ RAM_BASE+$16B
title_music_step        equ RAM_BASE+$16C
title_music_timer       equ RAM_BASE+$16D
title_logo_x            equ RAM_BASE+$16E
title_logo_y            equ RAM_BASE+$16F
title_logo_top          equ RAM_BASE+$170
title_logo_color        equ RAM_BASE+$171
title_glyph_count       equ RAM_BASE+$172
title_row_count         equ RAM_BASE+$173
title_col_count         equ RAM_BASE+$174
title_row_bits          equ RAM_BASE+$175
title_bit_mask          equ RAM_BASE+$176
title_cell_x            equ RAM_BASE+$177
title_font_ptr          equ RAM_BASE+$178 ; two-byte page-1 glyph stream pointer
current_player          equ RAM_BASE+$17A ; 0 player 1, 1 player 2
reserve_score_high      equ RAM_BASE+$17B ; Cartwright's seven reserve-player bytes
reserve_score_mid       equ RAM_BASE+$17C
reserve_score_low       equ RAM_BASE+$17D
reserve_player_subs     equ RAM_BASE+$17E
reserve_current_level   equ RAM_BASE+$17F
reserve_difficulty      equ RAM_BASE+$180
reserve_divers          equ RAM_BASE+$181
sub_club_claimed        equ RAM_BASE+$182 ; active player's one-shot achievement
reserve_sub_club        equ RAM_BASE+$183
sub_club_timer_low      equ RAM_BASE+$184 ; 600 VBlanks = ten seconds at 60 Hz
sub_club_timer_high     equ RAM_BASE+$185
sub_club_last_phase     equ RAM_BASE+$186 ; $FF forces the first banner draw
player_switch_count     equ RAM_BASE+$187 ; validation diagnostic
sub_club_bitmap_ptr     equ RAM_BASE+$188 ; two-byte ROM row pointer
title_fm_event_ptr      equ RAM_BASE+$18A ; two-byte V39 title score cursor

Init:
        di
        xor a
        ld (CLIKSW),a           ; KEY CLICK OFF without muting the PSG
        ld (debug_marker),a
        ld (wave_phase),a
        ld a,SCREEN5_MODE
        call CHGMOD
        ld a,1
        ld (debug_marker),a
        call Enable16x16Sprites
        ld a,2
        ld (debug_marker),a
        call SetBorderBlack
        ld a,3
        ld (debug_marker),a
        call LoadPalette
        ld a,4
        ld (debug_marker),a
        call ClearScreen
        ld a,5
        ld (debug_marker),a
        call DrawBackground
        ld a,6
        ld (debug_marker),a
        call LoadSpritePatterns
        ld a,7
        ld (debug_marker),a
        call InitSpriteColors
        ld a,8
        ld (debug_marker),a
        call InitState
        call InitAudio
        ld a,9
        ld (debug_marker),a
        call InitSpriteShadow
        ld a,10
        ld (debug_marker),a
        call UpdateSprites
        ld a,11
        ld (debug_marker),a
        call UploadSprites
        call InitTitle
        ld a,12
        ld (debug_marker),a
        ei

MainLoop:
        halt
        ld a,(title_active)
        or a
        jr z,.game_state
        call UpdateTitle
        jr MainLoop
.game_state:
        call UpdateSubClubBanner
        ld a,(game_over)
        or a
        jr z,.death_check
        call ReadGameOverRestart
        ld a,(title_active)
        or a
        jr nz,MainLoop
        call UpdateAnimation
        call UpdateWaves
        call UpdateAudio
        call UpdateSprites
        call UploadSprites
        jr MainLoop
.death_check:
        ld a,(death_timer)
        or a
        jr z,.live
        call UpdateDeathSequence
        call UpdateAnimation
        call UpdateWaves
        call CheckSharkDiverInteractions
        call UpdateLanes
        call UpdateDiver
        call UpdateAudio
        call UpdateSprites
        call UploadSprites
        jr MainLoop
.live:
        ld a,(reward_state)
        or a
        jr z,.playing
        call UpdateAnimation
        call UpdateWaves
        ; The original CheckToMoveEnemyPatrolSub path still runs during
        ; GS_INCREMENT_OXYGEN, but not during the oxygen/diver score phases.
        ; reward_state 3 is that final refill state in this port.
        ld a,(reward_state)
        cp 3
        call z,UpdatePatrolSub
        call UpdateSixDiverSequence
        call UpdateAudio
        call UpdateSprites
        call UploadSprites
        jr MainLoop
.playing:
        call ReadJoystick
        call UpdateTorpedo
        call UpdateAnimation
        call UpdateWaves
        call UpdateOxygen
        ld a,(reward_state)
        or a
        jr nz,.reward_started
        ; Consume the previous rendered TIA-style latch before moving either
        ; participant. Both then receive this frame's same integer lane step.
        call CheckSharkDiverInteractions
        call UpdateLanes
        call UpdatePatrolSub
        call UpdateEnemyTorpedoes
        call UpdateDiver
        call CheckCollisions
.reward_started:
        call UpdateAudio
        call UpdateSprites
        call UploadSprites
        jp MainLoop

; -----------------------------------------------------------------------------
; V38 front end.  It is a separate state from Cartwright's gameplay loop: while
; title_active is set, no formation, oxygen, score or collision byte advances.
; The selected mode is retained in game_mode and now starts either complete
; one-player play or the source-faithful alternating two-player state.
; -----------------------------------------------------------------------------
InitTitle:
        xor a
        ld (title_selection),a
        ld (title_move_latch),a
        ld (title_trigger_latch),a
        ld (title_frame),a
        ld (title_wave_phase),a
        ld (title_fade),a
        ld a,1
        ld (title_active),a
        ld (game_mode),a
        call InitSpriteShadow
        call UploadSprites
        call DetectInternalMsxMusic
        call DrawTitleScreen
        jp InitTitleMusic

UpdateTitle:
        ld hl,title_frame
        inc (hl)
        call UpdateTitleMusic
        call UpdateTitleWaves
        ld a,(title_fade)
        or a
        jp nz,UpdateTitleFade

        xor a
        call GTSTCK
        or a
        jr z,.direction_released
        cp 1
        jr z,.change_selection
        cp 5
        jr nz,.read_trigger
.change_selection:
        ld a,(title_move_latch)
        or a
        jr nz,.read_trigger
        ld a,1
        ld (title_move_latch),a
        ld a,(title_selection)
        xor 1
        ld (title_selection),a
        inc a
        ld (game_mode),a
        call DrawTitleMenu
        jr .read_trigger
.direction_released:
        xor a
        ld (title_move_latch),a
.read_trigger:
        xor a
        call GTTRIG
        or a
        jr z,.trigger_released
        ld a,(title_trigger_latch)
        or a
        ret nz
        ld a,1
        ld (title_trigger_latch),a
        xor a
        ld (title_fade),a
        inc a
        ld (title_fade),a
        jp StopTitleMusic
.trigger_released:
        xor a
        ld (title_trigger_latch),a
        ret

UpdateTitleFade:
        dec a
        ld l,a
        ld h,0
        ld de,TitleFadeY
        add hl,de
        ld d,(hl)
        ld a,(title_fade)
        dec a
        ld l,a
        ld h,0
        ld de,TitleFadeRows
        add hl,de
        ld e,(hl)
        xor a
        call FillViewportRows
        ld a,(title_fade)
        inc a
        ld (title_fade),a
        cp 13
        ret c
        jp StartGameplayFromTitle

StartGameplayFromTitle:
        call StopTitleMusic
        call LoadPalette
        call ClearScreen
        call DrawBackground
        call LoadSpritePatterns
        call InitSpriteColors
        call InitState
        call InitAudio
        call InitSpriteShadow
        call UpdateSprites
        call UploadSprites
        xor a
        ld (title_active),a
        ret

DrawTitleScreen:
        call ClearScreen
        ld a,$88                  ; box-art green field
        ld d,4
        ld e,66
        call FillViewportRows
        ld a,$77                  ; bright water lip
        ld d,70
        ld e,20
        call FillViewportRows
        ld a,$CC                  ; gameplay cobalt below it
        ld d,90
        ld e,108
        call FillViewportRows
        xor a
        ld d,198
        ld e,14
        call FillViewportRows
        call DrawTitleWaves
        call DrawTitleLogo
        call DrawTitleSubmarine
        call DrawTitleMenu
        jp DrawFooterSignature

; Eight 5x7 glyphs, enlarged to 4x4 SCREEN 5 pixels per source pixel.  A one
; pixel-style navy pass gives the logo a hardware-native shadow without using
; any gameplay sprite slots.
DrawTitleLogo:
        ld a,$FF
        ld (title_logo_color),a
        ld a,34
        ld (title_logo_x),a
        ld a,16
        ld (title_logo_top),a
        call DrawTitleLogoPass
        ld a,$55
        ld (title_logo_color),a
        ld a,32
        ld (title_logo_x),a
        ld a,14
        ld (title_logo_top),a
        jp DrawTitleLogoPass

DrawTitleLogoPass:
        ld hl,TitleLogoFont
        ld (title_font_ptr),hl
        ld a,8
        ld (title_glyph_count),a
.glyph:
        ld a,(title_logo_top)
        ld (title_logo_y),a
        ld a,7
        ld (title_row_count),a
.row:
        ld hl,(title_font_ptr)
        ld a,(hl)
        inc hl
        ld (title_font_ptr),hl
        ld (title_row_bits),a
        ld a,$10
        ld (title_bit_mask),a
        ld a,(title_logo_x)
        ld (title_cell_x),a
        ld a,5
        ld (title_col_count),a
.column:
        ld a,(title_row_bits)
        ld b,a
        ld a,(title_bit_mask)
        and b
        jr z,.blank
        push hl
        call DrawTitleLogoCell
        pop hl
.blank:
        ld a,(title_cell_x)
        add a,4
        ld (title_cell_x),a
        ld hl,title_bit_mask
        srl (hl)
        ld hl,title_col_count
        dec (hl)
        jr nz,.column
        ld a,(title_logo_y)
        add a,4
        ld (title_logo_y),a
        ld hl,title_row_count
        dec (hl)
        jr nz,.row
        ld a,(title_logo_x)
        add a,24
        ld (title_logo_x),a
        ld hl,title_glyph_count
        dec (hl)
        jr nz,.glyph
        ret

DrawTitleLogoCell:
        ld a,(title_logo_y)
        ld d,a
        ld e,4
        ld a,(title_cell_x)
        srl a
        ld h,a
        ld bc,2
        ld a,(title_logo_color)
        jp FillHudRectRows

DrawTitleWaves:
        ld a,(title_wave_phase)
        or a
        jr nz,.phase_b
        ld a,$55
        ld d,72
        ld e,2
        call FillViewportRows
        ld a,$77
        ld d,74
        ld e,4
        call FillViewportRows
        ld a,$CC
        ld d,78
        ld e,4
        jp FillViewportRows
.phase_b:
        ld a,$77
        ld d,72
        ld e,3
        call FillViewportRows
        ld a,$55
        ld d,75
        ld e,2
        call FillViewportRows
        ld a,$CC
        ld d,77
        ld e,5
        jp FillViewportRows

UpdateTitleWaves:
        ld a,(title_frame)
        and 7
        ret nz
        ld a,(title_wave_phase)
        xor 1
        ld (title_wave_phase),a
        jp DrawTitleWaves

; Large two-layer pixel submarine, deliberately independent from the 16x16
; protagonist patterns.  The title can therefore be changed without touching
; the collision-tested gameplay art.
DrawTitleSubmarine:
        ld a,$FF
        ld d,104
        ld e,18
        ld h,44
        ld bc,44
        call FillHudRectRows
        ld a,$66
        ld d,106
        ld e,14
        ld h,46
        ld bc,40
        call FillHudRectRows
        ld a,$FF
        ld d,108
        ld e,14
        ld h,38
        ld bc,8
        call FillHudRectRows
        ld a,$66
        ld d,110
        ld e,10
        ld h,40
        ld bc,6
        call FillHudRectRows
        ld a,$FF
        ld d,92
        ld e,14
        ld h,65
        ld bc,14
        call FillHudRectRows
        ld a,$66
        ld d,94
        ld e,12
        ld h,67
        ld bc,10
        call FillHudRectRows
        ld a,$FF
        ld d,86
        ld e,8
        ld h,70
        ld bc,4
        call FillHudRectRows
        ld a,$77
        ld d,110
        ld e,5
        ld h,58
        ld bc,3
        call FillHudRectRows
        ld a,$00
        ld d,111
        ld e,4
        ld h,80
        ld bc,4
        jp FillHudRectRows

DrawTitleMenu:
        ld a,$CC
        ld d,138
        ld e,60
        call FillViewportRows
        ld a,PAL_BLUE
        ld (BAKCLR),a
        ld a,PAL_WHITE
        ld (FORCLR),a
        ld hl,76
        ld (GRPACX),hl
        ld hl,142
        ld (GRPACY),hl
        ld hl,TitleStartText
        call PrintTitleString
        ld hl,80
        ld (GRPACX),hl
        ld hl,160
        ld (GRPACY),hl
        ld hl,TitleOnePlayerText
        call PrintTitleString
        ld hl,80
        ld (GRPACX),hl
        ld hl,176
        ld (GRPACY),hl
        ld hl,TitleTwoPlayerText
        call PrintTitleString
        ld a,PAL_YELLOW
        ld (FORCLR),a
        ld hl,64
        ld (GRPACX),hl
        ld a,(title_selection)
        or a
        ld hl,160
        jr z,.cursor_y_ready
        ld hl,176
.cursor_y_ready:
        ld (GRPACY),hl
        ld a,'>'
        jp GRPPRT

PrintTitleString:
        ld a,(hl)
        or a
        ret z
        push hl
        call GRPPRT
        pop hl
        inc hl
        jr PrintTitleString

; The original identifies the active player through both score and submarine
; color.  Yellow is player 1; the MSX2 cyan palette entry represents player 2.
GetCurrentPlayerColor:
        ld a,(current_player)
        or a
        ld a,PAL_YELLOW
        ret z
        ld a,PAL_CYAN
        ret

SetCurrentPlayerSpriteColor:
        call GetCurrentPlayerColor
        ld e,SPR_PLAYER
        jp SetSpriteColor

ApplyCurrentPlayerPresentation:
        call SetCurrentPlayerSpriteColor
        call DrawScoreValue
        call DrawReserveSubs
        call DrawRetrievedDivers
        jp DrawOxygenLevel

ClearSubClubBanner:
        ld a,$11                  ; packed PAL_SKY
        ld d,30
        ld e,7
        ld h,36                   ; screen x=72 pixels
        ld bc,57                  ; compact 5x7 phrase, 114 pixels
        jp FillHudRectRows

DrawSubClubBanner:
        ld a,(current_player)
        or a
        ld hl,SubClubColor6Bitmap
        jr z,DrawSubClubBitmap
        ld hl,SubClubColor7Bitmap

DrawSubClubBitmap:
        ld (sub_club_bitmap_ptr),hl
        ld a,30
        ld (bg_y),a
        ld a,7
        ld (bg_count),a
.row:
        ld hl,(sub_club_bitmap_ptr)
        push hl
        ld de,57
        add hl,de
        ld (sub_club_bitmap_ptr),hl
        pop hl
        ld a,(bg_y)
        srl a
        ld d,a
        ld e,36
        jr nc,.address_ready
        set 7,e
.address_ready:
        ld bc,57
        call LDIRVM
        ld hl,bg_y
        inc (hl)
        ld hl,bg_count
        dec (hl)
        jr nz,.row
        ret

StartSubClubBanner:
        ld a,$58                  ; $0258 = 600 frames
        ld (sub_club_timer_low),a
        ld a,$02
        ld (sub_club_timer_high),a
        ld a,1
        ld (sub_club_last_phase),a
        jp DrawSubClubBanner

UpdateSubClubBanner:
        ld a,(sub_club_timer_low)
        ld b,a
        ld a,(sub_club_timer_high)
        or b
        ret z
        ld hl,sub_club_timer_low
        ld a,(hl)
        or a
        jr nz,.decrement_low
        inc hl
        dec (hl)
        dec hl
        ld (hl),$FF
        jr .decremented
.decrement_low:
        dec (hl)
.decremented:
        ld a,(sub_club_timer_low)
        ld b,a
        ld a,(sub_club_timer_high)
        or b
        jr nz,.phase
        ld a,$FF
        ld (sub_club_last_phase),a
        jp ClearSubClubBanner
.phase:
        ld a,(sub_club_timer_low)
        and $10
        jr z,.phase_ready
        ld a,1
.phase_ready:
        ld b,a
        ld a,(sub_club_last_phase)
        cp b
        ret z
        ld a,b
        ld (sub_club_last_phase),a
        or a
        jp z,ClearSubClubBanner
        jp DrawSubClubBanner

; Detect only the internal MSX-MUSIC form, identified by APRLOPLL at 4018h in
; any primary/subslot.  Direct ports 7Ch/7Dh are then safe.  External FM-PAC
; activation is intentionally not guessed; it receives the PSG fallback.
DetectInternalMsxMusic:
        xor a
        ld (fm_available),a
        ld (fm_primary),a
.primary_loop:
        ld a,(fm_primary)
        ld e,a
        ld d,0
        ld hl,EXPTBL
        add hl,de
        bit 7,(hl)
        jr nz,.expanded
        ld a,(fm_primary)
        call CheckInternalMsxMusicSlot
        jr c,.found
        jr .next_primary
.expanded:
        xor a
        ld (fm_secondary),a
.secondary_loop:
        ld a,(fm_secondary)
        add a,a
        add a,a
        ld b,a
        ld a,(fm_primary)
        or b
        or $80
        call CheckInternalMsxMusicSlot
        jr c,.found
        ld a,(fm_secondary)
        inc a
        ld (fm_secondary),a
        cp 4
        jr c,.secondary_loop
.next_primary:
        ld a,(fm_primary)
        inc a
        ld (fm_primary),a
        cp 4
        jr c,.primary_loop
        ret
.found:
        ld a,1
        ld (fm_available),a
        ret

CheckInternalMsxMusicSlot:
        ld (fm_probe_slot),a
        push bc
        push de
        push hl
        ld hl,$4018
        ld de,MsxMusicSignature
        ld b,8
.byte:
        push bc
        push de
        push hl
        ld a,(fm_probe_slot)
        call RDSLT
        ld (fm_probe_value),a
        pop hl
        pop de
        pop bc
        ld a,(de)
        ld c,a
        ld a,(fm_probe_value)
        cp c
        jr nz,.miss
        inc hl
        inc de
        djnz .byte
        scf
        jr .done
.miss:
        or a                       ; clear carry
.done:
        pop hl
        pop de
        pop bc
        ret

InitTitleMusic:
        xor a
        ld (title_music_step),a
        inc a
        ld (title_music_timer),a
        ld hl,TitleYellowFmEvents
        ld (title_fm_event_ptr),hl
        ld a,(fm_available)
        or a
        jr z,.psg
        ld e,0
        ld a,$20
        call OpllWrite
        ld e,0
        ld a,$21
        call OpllWrite
        ld e,0
        ld a,$22
        call OpllWrite
        ld e,$32                  ; YELLOW_FM.BAS @3: lead, strong and rounded
        ld a,$30
        call OpllWrite
        ld e,$A7                  ; @10 approximation: quieter harmony
        ld a,$31
        call OpllWrite
        ld e,$D8                  ; low-register bass approximation
        ld a,$32
        jp OpllWrite
.psg:
        ld a,7
        call RDPSG
        and $C0
        or $3B                    ; channel C tone only
        ld e,a
        ld a,7
        call WRTPSG
        xor a
        ld e,a
        ld a,10
        jp WRTPSG

UpdateTitleMusic:
        ld hl,title_music_timer
        dec (hl)
        ret nz
        ld a,(fm_available)
        or a
        jp nz,PlayTitleFmEvent
        ld (hl),10                ; original V38 PSG fallback remains compact
        call PlayTitlePsgNote
        jp AdvanceTitleMusicStep

; Seven-byte events: duration at 60 Hz, then F-number/key bytes for lead,
; harmony and bass.  Quarter note = 32 frames, i.e. 112.5 BPM (the supplied
; YELLOW_FM.BAS requests 112 BPM). A zero duration loops the short title cue.
PlayTitleFmEvent:
        ld hl,(title_fm_event_ptr)
.read_event:
        ld a,(hl)
        or a
        jr nz,.have_duration
        ld hl,TitleYellowFmEvents
        jr .read_event
.have_duration:
        ld (title_music_timer),a
        inc hl
        ld e,0                    ; articulate all three voices together
        ld a,$20
        call OpllWrite
        ld e,0
        ld a,$21
        call OpllWrite
        ld e,0
        ld a,$22
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$10
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$20
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$11
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$21
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$12
        call OpllWrite
        ld e,(hl)
        inc hl
        ld a,$22
        call OpllWrite
        ld (title_fm_event_ptr),hl
        ret

PlayTitlePsgNote:
        ld a,(title_music_step)
        add a,a
        ld l,a
        ld h,0
        ld de,TitlePsgPeriods
        add hl,de
        ld e,(hl)
        ld a,4
        call WRTPSG
        inc hl
        ld e,(hl)
        ld a,5
        call WRTPSG
        ld a,(hl)
        or a
        jr nz,.audible
        dec hl
        ld a,(hl)
        or a
        jr nz,.audible
        xor a
        jr .volume
.audible:
        ld a,9
.volume:
        ld e,a
        ld a,10
        jp WRTPSG

AdvanceTitleMusicStep:
        ld a,(title_music_step)
        inc a
        and 15
        ld (title_music_step),a
        ret

StopTitleMusic:
        ld a,(fm_available)
        or a
        jr z,.psg
        ld e,0
        ld a,$20
        call OpllWrite
        ld e,0
        ld a,$21
        call OpllWrite
        ld e,0
        ld a,$22
        call OpllWrite
        ld e,$0F
        ld a,$30
        call OpllWrite
        ld e,$0F
        ld a,$31
        call OpllWrite
        ld e,$0F
        ld a,$32
        jp OpllWrite
.psg:
        xor a
        ld e,a
        ld a,10
        jp WRTPSG

; A=register, E=data.  The waits exceed the YM2413 minimum 12/84 clock delays.
OpllWrite:
        out ($7C),a
        nop
        nop
        nop
        ld a,e
        out ($7D),a
        push bc
        ld b,7
.wait:
        djnz .wait
        pop bc
        ret

Enable16x16Sprites:
        ld a,(RG1SAV)
        or SPRITE_SIZE_16
        and %11111110          ; no magnification
        ld (RG1SAV),a
        ld b,a
        ld c,1
        jp WRTVDP

SetBorderBlack:
        xor a
        ld (BDRCLR),a
        ld (RG7SAV),a
        ld b,a
        ld c,7
        jp WRTVDP

LoadPalette:
        di
        xor a
        out ($99),a
        ld a,$90              ; register 16, palette index 0
        out ($99),a
        ld hl,PaletteData
        ld b,32
.loop:
        ld a,(hl)
        out ($9A),a
        inc hl
        djnz .loop
        ei
        ret

ClearScreen:
        ld hl,$0000
        ld bc,VISIBLE_VRAM_BYTES
        xor a
        jp FILVRM

; Fill the centered 240-pixel viewport with horizontal color bands.
DrawBackground:
        ld a,$11              ; reference sky: MSX2 RGB 2,3,7
        ld d,4
        ld e,14
        call FillViewportRows
        ld a,$11              ; middle sky
        ld d,18
        ld e,12
        call FillViewportRows
        ld a,$11              ; solid gradient transition (no pixel comb)
        ld d,30
        ld e,4
        call FillViewportRows
        ld a,$11              ; uniform reference sky
        ld d,34
        ld e,14
        call FillViewportRows
        ld a,$66              ; Atari's ten-line horizon palette
        ld d,48
        ld e,1
        call FillViewportRows
        ld a,$66
        ld d,49
        ld e,1
        call FillViewportRows
        ld a,$BB
        ld d,50
        ld e,2
        call FillViewportRows
        ld a,$33
        ld d,52
        ld e,2
        call FillViewportRows
        ld a,$AA
        ld d,54
        ld e,2
        call FillViewportRows
        ld a,$CC
        ld d,56
        ld e,2
        call FillViewportRows
        ld a,$CC              ; deep blue gameplay sea
        ld d,SEA_SURFACE_Y
        ld e,REEF_TOP_Y-SEA_SURFACE_Y
        call FillViewportRows
        ld a,$DD              ; expanded gray HUD foundation
        ld d,REEF_TOP_Y
        ld e,FOOTER_TOP_Y-REEF_TOP_Y
        call FillViewportRows
        ld a,$00              ; HUD/footer
        ld d,FOOTER_TOP_Y
        ld e,212-FOOTER_TOP_Y ; cover every remaining visible SCREEN 5 row
        call FillViewportRows
        call DrawAnimatedWaves
        call DrawSeaFloorReef
        call DrawHudScaffold
        call DrawFooterSignature
        ret

; The footer is a fixed 5x7 bitmap so the complete 37-character credit fits
; inside the 240-pixel logical viewport without changing the HUD geometry.
DrawFooterSignature:
        ld hl,FooterSignatureRow0
        ld de,((FOOTER_TOP_Y+4)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow1
        ld de,((FOOTER_TOP_Y+5)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow2
        ld de,((FOOTER_TOP_Y+6)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow3
        ld de,((FOOTER_TOP_Y+7)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow4
        ld de,((FOOTER_TOP_Y+8)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow5
        ld de,((FOOTER_TOP_Y+9)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        call LDIRVM
        ld hl,FooterSignatureRow6
        ld de,((FOOTER_TOP_Y+10)*128)+(VIEWPORT_BYTES_X+4)
        ld bc,111
        jp LDIRVM

DrawSurfaceWaves:
        ld hl,SurfaceWaveRow0
        ld de,(SEA_SURFACE_Y*128)+VIEWPORT_BYTES_X
        ld bc,120
        call LDIRVM
        ld hl,SurfaceWaveRow1
        ld de,((SEA_SURFACE_Y+1)*128)+VIEWPORT_BYTES_X
        ld bc,120
        jp LDIRVM

; The Atari kernel modulates ten surface scanlines with an LFSR. Here the
; animation remains at 7.5 Hz, but only a subtle solid-color crest moves
; through otherwise uniform water, avoiding a striped/checkerboard field.
UpdateWaves:
        ld a,(frame_counter)
        and 7
        ret nz
        ld a,(wave_phase)
        inc a
        and 3
        ld (wave_phase),a
        jp DrawAnimatedWaves

DrawAnimatedWaves:
        ld hl,WaveColorPhases
        ld a,(wave_phase)
        or a
        jr z,.table_ready
        ld de,10
.select_phase:
        add hl,de
        dec a
        jr nz,.select_phase
.table_ready:
        ld a,SEA_SURFACE_Y
        ld (wave_draw_y),a
        ld a,10
        ld (wave_draw_count),a
.row:
        push hl
        ld a,(hl)
        ld d,a
        ld a,(wave_draw_y)
        ld b,a
        ld a,d
        ld d,b
        ld e,1
        call FillViewportRows
        pop hl
        inc hl
        ld a,(wave_draw_y)
        inc a
        ld (wave_draw_y),a
        ld a,(wave_draw_count)
        dec a
        ld (wave_draw_count),a
        jr nz,.row
        ret

DrawSeaFloorReef:
        ld hl,ReefRow0
        ld de,(REEF_TOP_Y*128)+VIEWPORT_BYTES_X
        ld bc,120
        call LDIRVM
        ld hl,ReefRow1
        ld de,((REEF_TOP_Y+1)*128)+VIEWPORT_BYTES_X
        ld bc,120
        call LDIRVM
        ld hl,ReefRow2
        ld de,((REEF_TOP_Y+2)*128)+VIEWPORT_BYTES_X
        ld bc,120
        call LDIRVM
        ld hl,ReefRow3
        ld de,((REEF_TOP_Y+3)*128)+VIEWPORT_BYTES_X
        ld bc,120
        jp LDIRVM

; A=packed color, D=start Y, E=row count
FillViewportRows:
        ld (bg_color),a
        ld a,d
        ld (bg_y),a
        ld a,e
        ld (bg_count),a
.row:
        ld a,(bg_y)
        srl a
        ld h,a
        ld l,VIEWPORT_BYTES_X
        jr nc,.address_ready
        set 7,l
.address_ready:
        ld bc,VIEWPORT_WIDTH_BYTES
        ld a,(bg_color)
        call FILVRM
        ld hl,bg_y
        inc (hl)
        ld hl,bg_count
        dec (hl)
        jr nz,.row
        ret

DrawLaneSeparators:
        ld a,$EE
        ld d,LANE1_Y-1
        ld e,1
        call FillViewportRows
        ld d,LANE2_Y-1
        ld e,1
        call FillViewportRows
        ld d,LANE3_Y-1
        ld e,1
        call FillViewportRows
        ret

DrawHudScaffold:
        call DrawScoreText
        call DrawOxygenText
        ; Oxygen bar beside its label; lower HUD remains free for divers.
        xor a
        ld d,HUD_OXYGEN_Y
        ld e,8
        ld h,VIEWPORT_BYTES_X+32
        ld bc,84
        call FillHudRectRows
        ; Full white 160x4 oxygen placeholder for the dynamic HUD pass.
        ld a,$55
        ld d,HUD_OXYGEN_BAR_Y
        ld e,4
        ld h,VIEWPORT_BYTES_X+34
        ld bc,80
        jp FillHudRectRows

DrawScoreText:
        ld a,PAL_YELLOW
        ld (FORCLR),a
        ld a,PAL_SKY
        ld (BAKCLR),a
        ld hl,104
        ld (GRPACX),hl
        ld hl,8
        ld (GRPACY),hl
        ld a,'0'
        call GRPPRT
        ld a,'0'
        call GRPPRT
        ld a,'0'
        call GRPPRT
        ld a,'0'
        call GRPPRT
        ld a,'0'
        call GRPPRT
        ld a,'0'
        jp GRPPRT

; Redraw the six packed-BCD score digits in the established HUD position.
DrawScoreValue:
        call GetCurrentPlayerColor
        ld (FORCLR),a
        ld a,PAL_SKY
        ld (BAKCLR),a
        ld hl,104
        ld (GRPACX),hl
        ld hl,8
        ld (GRPACY),hl
        ld a,(score_bcd_high)
        call DrawPackedBcdByte
        ld a,(score_bcd_mid)
        call DrawPackedBcdByte
        ld a,(score_bcd_low)
        jp DrawPackedBcdByte

DrawPackedBcdByte:
        push af
        and $F0
        rrca
        rrca
        rrca
        rrca
        add a,'0'
        call GRPPRT
        pop af
        and $0F
        add a,'0'
        jp GRPPRT

DrawOxygenText:
        ld a,PAL_BLACK
        ld (FORCLR),a
        ld a,PAL_DARK_GRAY
        ld (BAKCLR),a
        ld hl,12
        ld (GRPACX),hl
        ld hl,HUD_OXYGEN_Y
        ld (GRPACY),hl
        ld a,'O'
        call GRPPRT
        ld a,'X'
        call GRPPRT
        ld a,'Y'
        call GRPPRT
        ld a,'G'
        call GRPPRT
        ld a,'E'
        call GRPPRT
        ld a,'N'
        jp GRPPRT

DrawLivesPlaceholder:
DrawReserveSubs:
        ; Clear all six possible reserve positions in the sky HUD.
        ld a,$11
        ld d,9
        ld e,6
        ld h,VIEWPORT_BYTES_X+8
        ld bc,30
        call FillHudRectRows
        ld a,(reserve_subs)
        or a
        ret z
        ld (hud_life_count),a
        ld a,VIEWPORT_BYTES_X+8
        ld (hud_life_x),a
.icon:
        ld hl,ReserveSubIconRows
        ld (hud_life_src),hl
        ld a,9
        ld (bg_y),a
        ld a,6
        ld (hud_diver_rows),a
.row:
        ; LDIRVM does not provide a portable post-call source pointer. Advance
        ; our own copy before the BIOS call so every row reads exactly 5 bytes.
        ld hl,(hud_life_src)
        push hl
        ld de,5
        add hl,de
        ld (hud_life_src),hl
        pop hl
        ld a,(bg_y)
        srl a
        ld d,a
        ld a,(hud_life_x)
        ld e,a
        jr nc,.address_ready
        set 7,e
.address_ready:
        ld bc,5
        call LDIRVM
        ld hl,bg_y
        inc (hl)
        ld hl,hud_diver_rows
        dec (hl)
        jr nz,.row
        ld a,(hud_life_x)
        add a,5
        ld (hud_life_x),a
        ld hl,hud_life_count
        dec (hl)
        jr nz,.icon
        ret

DrawScorePlaceholder:
        ld hl,HudScoreRows
        ld de,(10*128)+(VIEWPORT_BYTES_X+54)
        ld bc,12
        call LDIRVM
        ld de,(11*128)+(VIEWPORT_BYTES_X+54)
        ld bc,12
        call LDIRVM
        ld de,(12*128)+(VIEWPORT_BYTES_X+54)
        ld bc,12
        call LDIRVM
        ld de,(13*128)+(VIEWPORT_BYTES_X+54)
        ld bc,12
        call LDIRVM
        ld de,(14*128)+(VIEWPORT_BYTES_X+54)
        ld bc,12
        jp LDIRVM

DrawOxygenLabel:
        ld hl,HudOxygenRows
        ld de,(HUD_OXYGEN_Y*128)+(VIEWPORT_BYTES_X+2)
        ld bc,12
        call LDIRVM
        ld de,((HUD_OXYGEN_Y+1)*128)+(VIEWPORT_BYTES_X+2)
        ld bc,12
        call LDIRVM
        ld de,((HUD_OXYGEN_Y+2)*128)+(VIEWPORT_BYTES_X+2)
        ld bc,12
        call LDIRVM
        ld de,((HUD_OXYGEN_Y+3)*128)+(VIEWPORT_BYTES_X+2)
        ld bc,12
        call LDIRVM
        ld de,((HUD_OXYGEN_Y+4)*128)+(VIEWPORT_BYTES_X+2)
        ld bc,12
        jp LDIRVM

; A=color, D=start Y, E=row count, H=byte X, BC=byte width.
FillHudRectRows:
        ld (bg_color),a
        ld a,d
        ld (bg_y),a
        ld a,e
        ld (bg_count),a
        ld a,h
        ld (hud_rect_x),a
        ld a,c
        ld (hud_rect_width),a
.row:
        ld a,(bg_y)
        srl a
        ld h,a
        ld a,(hud_rect_x)
        ld l,a
        jr nc,.address_ready
        set 7,l
.address_ready:
        ld a,(hud_rect_width)
        ld c,a
        ld b,0
        ld a,(bg_color)
        call FILVRM
        ld hl,bg_y
        inc (hl)
        ld hl,bg_count
        dec (hl)
        jr nz,.row
        ret

LoadSpritePatterns:
        ld hl,SpritePatterns
        ld de,SPRITE_PATTERN_TABLE
        ld bc,SpritePatternsEnd-SpritePatterns
        jp LDIRVM

InitSpriteColors:
        ld e,SPR_PLAYER_OUTLINE
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_PLAYER
        ld a,PAL_YELLOW
        call SetSpriteColor
        ld e,SPR_TORPEDO
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_LANE0
        ld a,PAL_GREEN
        call SetThreeSpriteColors
        ld e,SPR_LANE1
        ld a,PAL_BROWN
        call SetThreeSpriteColors
        ld e,SPR_LANE2
        ld a,PAL_PURPLE
        call SetThreeSpriteColors
        ld e,SPR_LANE3
        ld a,PAL_RED
        call SetThreeSpriteColors
        ld e,SPR_DIVER0
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_DIVER1
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_DIVER2
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_DIVER3
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0+1
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0+2
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0+3
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0+4
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_HUD_DIVER0+5
        ld a,PAL_OUTLINE
        call SetSpriteColor
        ld e,SPR_ENEMY_TORPEDO0
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_ENEMY_TORPEDO1
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_ENEMY_TORPEDO2
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_ENEMY_TORPEDO3
        ld a,PAL_WHITE
        call SetSpriteColor
        ld e,SPR_PATROL_SUB
        ld a,PAL_PATROL_GRAY
        jp SetSpriteColor

; A=color, E=first sprite index
SetThreeSpriteColors:
        push af
        call SetSpriteColor
        inc e
        pop af
        push af
        call SetSpriteColor
        inc e
        pop af
        jp SetSpriteColor

; A=color, E=sprite index
SetSpriteColor:
        push af
        ld a,e
        add a,a
        add a,a
        add a,a
        add a,a
        ld l,a
        ld h,$74
        jr nc,.no_page_carry
        inc h
.no_page_carry:
        pop af
        ld bc,16
        jp FILVRM

InitState:
        xor a
        ld (CLIKSW),a           ; keep restart-after-game-over silent too
        ld a,112
        ld (player_x),a
        ld a,13
        ld (player_y),a
        xor a
        ld (player_facing),a
        ld (player_anim),a
        ld (anim_tick),a
        ld (torpedo_active),a
        ld (frame_counter),a
        ld (lane_frac_0),a
        ld (lane_frac_1),a
        ld (lane_frac_2),a
        ld (lane_frac_3),a
        ld (game_difficulty),a
        ld (shark_float),a
        ld a,1
        ld (formation_random_seed),a
        xor a
        ld (lane_mask_0),a
        ld (lane_mask_1),a
        ld (lane_mask_2),a
        ld (lane_mask_3),a
        ld (lane_type_0),a
        ld (lane_type_1),a
        ld (lane_type_2),a
        ld (lane_type_3),a
        ld ix,formation_anchor_0
        ld iy,lane_mask_0
        ld hl,lane_frac_0
        ld de,lane_dir_0
        call ResetKilledFormation
        ld ix,formation_anchor_1
        ld iy,lane_mask_1
        ld hl,lane_frac_1
        ld de,lane_dir_1
        call ResetKilledFormation
        ld ix,formation_anchor_2
        ld iy,lane_mask_2
        ld hl,lane_frac_2
        ld de,lane_dir_2
        call ResetKilledFormation
        ld ix,formation_anchor_3
        ld iy,lane_mask_3
        ld hl,lane_frac_3
        ld de,lane_dir_3
        call ResetKilledFormation
        ld a,90                 ; safe launch window: 1.5 seconds at 60 Hz
        ld (player_grace),a
        ld a,MAX_OXYGEN_VALUE
        ld (oxygen_value),a
        ld ix,diver_state_0
        ld (ix+0),0
        ld (ix+1),20
        ld (ix+2),0
        ld (ix+3),0
        ld ix,diver_state_1
        ld (ix+0),0
        ld (ix+1),82
        ld (ix+2),1
        ld (ix+3),0
        ld ix,diver_state_2
        ld (ix+0),0
        ld (ix+1),144
        ld (ix+2),0
        ld (ix+3),0
        ld ix,diver_state_3
        ld (ix+0),0
        ld (ix+1),206
        ld (ix+2),1
        ld (ix+3),0
        xor a
        ld (diver_fast_0),a
        ld (diver_fast_1),a
        ld (diver_fast_2),a
        ld (diver_fast_3),a
        ld a,$FF
        ld (hud_diver_blink_color),a
        xor a
        inc a
        ld (lane_reset_0),a
        ld (lane_reset_1),a
        ld (lane_reset_2),a
        ld (lane_reset_3),a
        xor a
        ld (retrieved_divers),a
        ld (hud_diver_blink_active),a
        ld (sfx_pickup_counter),a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld (sfx_torpedo_counter),a
        ld (sfx_reward_counter),a
        ld (collision_confirm),a
        ld (collision_seen),a
        ld (death_reason),a
        ld (death_timer),a
        ld (reward_state),a
        ld (current_level),a
        ld (score_bcd_high),a
        ld (score_bcd_mid),a
        ld (score_bcd_low),a
        ld (formation_edge_resets),a
        ld (formation_kill_resets),a
        ld (formation_shot_count),a
        ld (enemy_torpedo_spawns),a
        ld (enemy_torpedo_hits),a
        ld (game_over),a
        ld (extra_life_awards),a
        ld (lane_step_0),a
        ld (lane_step_1),a
        ld (lane_step_2),a
        ld (lane_step_3),a
        ld (active_lane_step),a
        ld (patrol_source_x),a
        ld (patrol_screen_x),a
        ld (patrol_moves),a
        ld (patrol_hits),a
        ld (patrol_visible),a
        ld (current_player),a
        ld (reserve_score_high),a
        ld (reserve_score_mid),a
        ld (reserve_score_low),a
        ld (reserve_current_level),a
        ld (reserve_difficulty),a
        ld (reserve_divers),a
        ld (sub_club_claimed),a
        ld (reserve_sub_club),a
        ld (sub_club_timer_low),a
        ld (sub_club_timer_high),a
        ld (player_switch_count),a
        dec a
        ld (sub_club_last_phase),a
        ld a,(game_mode)
        cp 2
        ld a,0
        jr nz,.reserve_player_ready
        ; The 2600 stores four for the waiting player, then consumes one when
        ; that player first enters after player 1's death: both visibly get 3.
        ld a,4
.reserve_player_ready:
        ld (reserve_player_subs),a
        ld a,3
        ld (reserve_subs),a
        call UpdateCurrentPointValue
        call ClearSubClubBanner
        jp ApplyCurrentPlayerPresentation

; Atari timing: oxygen changes by one unit every 32 frames below YMIN+7.
; At the surface, a partial tank requires a rescued diver. One diver is consumed
; when the tank becomes full. Surfacing without one is fatal, as in the 2600 game.
UpdateOxygen:
        ld a,(player_y)
        cp OXYGEN_DIVE_THRESHOLD
        jr c,.surface
        ld a,(frame_counter)
        and $1F
        ret nz
        ld a,(oxygen_value)
        or a
        ret z
        dec a
        ld (oxygen_value),a
        call DrawOxygenLevel
        ld a,(oxygen_value)
        or a
        ret nz
        ld a,2
        ld (death_reason),a
        jp BeginPlayerDeath
.surface:
        cp PLAYER_Y_MIN
        ret nz
        ; Reaching the top ends the six-rescue signal as an event, even in the
        ; exceptional case where the oxygen tank is already full.
        xor a
        ld (hud_diver_blink_active),a
        ld a,(oxygen_value)
        cp MAX_OXYGEN_VALUE
        ret nc
        ld a,(retrieved_divers)
        or a
        jr nz,.has_diver
        ld a,2
        ld (death_reason),a
        jp BeginPlayerDeath
.has_diver:
        ld a,(retrieved_divers)
        cp 6
        jr c,.refill
        jp BeginSixDiverSequence
.refill:
        ld a,(frame_counter)
        and 1
        ret nz
        ld a,(oxygen_value)
        inc a
        ld (oxygen_value),a
        call DrawOxygenLevel
        ld a,(oxygen_value)
        cp MAX_OXYGEN_VALUE
        ret c
        ld hl,retrieved_divers
        dec (hl)
        ld hl,game_difficulty
        inc (hl)
        jp DrawRetrievedDivers

; Cartwright's GameProcessing sequence freezes the playfield while it:
; 1) converts one oxygen unit every two frames, 2) awards one rescued diver
; every 16 frames, then 3) refills oxygen at the normal two-frame cadence.
; V33 translates each of those source phases to the MSX PSG without changing
; this gameplay state machine.
BeginSixDiverSequence:
        ld a,(reward_state)
        or a
        ret nz
        ld a,1
        ld (reward_state),a
        xor a
        ld (torpedo_active),a
        ld (sfx_torpedo_counter),a
        ld (collision_confirm),a
        ld (collision_seen),a
        ret

UpdateSixDiverSequence:
        ld a,(reward_state)
        cp 1
        jr z,.oxygen_reward
        cp 2
        jr z,.diver_reward
        ; GS_INCREMENT_OXYGEN: deliberately identical to normal refill speed.
        ld a,(frame_counter)
        and 1
        ret nz
        ld a,(oxygen_value)
        cp MAX_OXYGEN_VALUE
        jr nc,.finish
        inc a
        ld (oxygen_value),a
        call DrawOxygenLevel
        ld a,(oxygen_value)
        cp MAX_OXYGEN_VALUE
        ret c
.finish:
        xor a
        ld (reward_state),a
        ld a,90
        ld (player_grace),a
        ret

.oxygen_reward:
        ld a,(oxygen_value)
        or a
        jr z,.begin_divers
        ld a,(frame_counter)
        and 1
        ret nz
        ld a,(oxygen_value)
        dec a
        ld (oxygen_value),a
        call DrawOxygenLevel
        ld a,(current_point_value)
        call IncrementScoreBcd
        call DrawScoreValue
        ld a,(oxygen_value)
        or a
        ret nz
.begin_divers:
        ld a,2
        ld (reward_state),a
        ret

.diver_reward:
        ld a,(frame_counter)
        and $0F
        ret nz
        ld a,(retrieved_divers)
        or a
        jr z,.begin_refill
        dec a
        ld (retrieved_divers),a
        ld a,31
        ld (sfx_reward_counter),a
        call DrawRetrievedDivers
        call AddRetrievedDiverBonus
        ; The original waits for the next 16-frame reward boundary before it
        ; observes zero divers and advances the level.
        ret
.begin_refill:
        ld hl,current_level
        inc (hl)
        ld a,(game_difficulty)
        ld b,a
        ld a,(current_level)
        cp b
        jr c,.difficulty_ready
        jr z,.difficulty_ready
        ld hl,game_difficulty
        inc (hl)
.difficulty_ready:
        call UpdateCurrentPointValue
        ; ResetObstacleHorizPositions in the original removes all formations
        ; before GS_INCREMENT_OXYGEN; new source masks spawn after refill.
        xor a
        ld (lane_mask_0),a
        ld (lane_mask_1),a
        ld (lane_mask_2),a
        ld (lane_mask_3),a
        ld (lane_visible_0),a
        ld (lane_visible_1),a
        ld (lane_visible_2),a
        ld (lane_visible_3),a
        ; ResetObstacleHorizPositions also clears all four shared BALL/diver X
        ; positions. Preserve each diver-array state byte, but remove projectiles
        ; and fractional residue before the post-reward shark rebuild.
        ld (diver_state_0+1),a
        ld (diver_state_0+3),a
        ld (diver_state_1+1),a
        ld (diver_state_1+3),a
        ld (diver_state_2+1),a
        ld (diver_state_2+3),a
        ld (diver_state_3+1),a
        ld (diver_state_3+3),a
        ld a,3
        ld (reward_state),a
        ret

; currentPointValue = min(currentLevel + 2, 9) * 10, packed as BCD.
UpdateCurrentPointValue:
        ld a,(current_level)
        add a,2
        cp 9
        jr c,.point_ready
        ld a,9
.point_ready:
        add a,a
        add a,a
        add a,a
        add a,a
        ld (current_point_value),a
        ret

; Add packed-BCD A to the six-digit score. Seaquest awards multiples of ten.
IncrementScoreBcd:
        ld hl,score_bcd_low
        add a,(hl)
        daa
        ld (hl),a
        jr nc,.score_done
        dec hl
        ld a,(hl)
        adc a,0
        daa
        ld (hl),a
        jr nc,.score_done
        dec hl
        ld a,(hl)
        adc a,0
        daa
        ld (hl),a
        jr nc,.award_reserve
        ld a,$99
        ld (score_bcd_high),a
        ld (score_bcd_mid),a
        ld a,$90
        ld (score_bcd_low),a
        jr .score_done
.award_reserve:
        ; A carry into the high BCD byte is exactly a 10,000-point boundary.
        ; The original grants one reserve here, capped at six.
        ld a,(reserve_subs)
        cp MAX_RESERVED_SUBS
        jr nc,.score_done
        inc a
        ld (reserve_subs),a
        ld hl,extra_life_awards
        inc (hl)
        call DrawReserveSubs
.score_done:
        jp CheckSubClubThreshold

; V38 extension requested for long play.  Packed BCD $05xxxx means that the
; active player has crossed 50,000.  Each player's latch travels with the same
; active/reserve state swap as Cartwright's seven original bytes.
CheckSubClubThreshold:
        ld a,(sub_club_claimed)
        or a
        ret nz
        ld a,(score_bcd_high)
        cp $05
        ret c
        ld a,1
        ld (sub_club_claimed),a
        jp StartSubClubBanner

; Each diver in the six-diver reward is worth 50 * (currentLevel + 1),
; with Cartwright's level multiplier capped at level 19.
AddRetrievedDiverBonus:
        ld a,(current_level)
        cp 19
        jr c,.bonus_level_ready
        ld a,19
.bonus_level_ready:
        inc a
        ld b,a
.bonus_loop:
        push bc
        ld a,$50
        call IncrementScoreBcd
        pop bc
        djnz .bonus_loop
        jp DrawScoreValue

; Convert 0..64 oxygen units into 0..80 SCREEN 5 bytes (0..160 pixels).
DrawOxygenLevel:
        xor a
        ld d,HUD_OXYGEN_BAR_Y
        ld e,4
        ld h,VIEWPORT_BYTES_X+34
        ld bc,80
        call FillHudRectRows
        ld a,(oxygen_value)
        ld l,a
        ld h,0
        ld e,a
        ld d,0
        add hl,hl
        add hl,hl
        add hl,de
        srl h
        rr l
        srl h
        rr l
        ld a,l
        or a
        ret z
        ld c,a
        ld b,0
        ld a,(oxygen_value)
        cp 17
        ld a,$55
        jr nc,.color_ready
        ld a,(frame_counter)
        and 16
        ld a,$BB
        jr z,.color_ready
        ld a,$55
.color_ready:
        ld d,HUD_OXYGEN_BAR_Y
        ld e,4
        ld h,VIEWPORT_BYTES_X+34
        jp FillHudRectRows

; Runtime VRAM writes were removed from the HUD. The SAT is refreshed every
; frame, so pickup/consumption becomes visible safely on the next frame.
DrawRetrievedDivers:
        ret

; -----------------------------------------------------------------------------
; PSG translation of Cartwright's two TIA audio channels
;
; Priority remains source-owned:
;   death > reward/refill > player torpedo on channel A;
;   diver pickup > oxygen warning > shark/sub hit on channel B.
; TIA control 12/15 becomes AY tone and control 8 becomes AY noise. Divider
; timing, envelopes and event lengths remain governed by the Atari counters.
; -----------------------------------------------------------------------------
InitAudio:
        xor a
        ld (sfx_pickup_counter),a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld (sfx_torpedo_counter),a
        ld (sfx_reward_counter),a
        ld (psg_last_period_a_low),a
        ld (psg_last_period_a_high),a
        ld (psg_last_period_b_low),a
        ld (psg_last_period_b_high),a
        call PsgBeginFrame
        jp WritePsgMixer

UpdateAudio:
        call PsgBeginFrame
        ld a,(game_over)
        or a
        jp nz,WritePsgMixer
        ld a,(death_timer)
        or a
        jr z,.reward
        call PlayDeathAudio
        jp WritePsgMixer
.reward:
        ld a,(reward_state)
        or a
        jr z,.normal_play
        call PlayRewardAudio
        jp WritePsgMixer
.normal_play:
        ; Normal surface refill uses the same dual-channel source routine as
        ; GS_INCREMENT_OXYGEN and therefore overrides the torpedo channel.
        ld a,(player_y)
        cp PLAYER_Y_MIN
        jr nz,.effects
        ld a,(oxygen_value)
        cp MAX_OXYGEN_VALUE
        jr nc,.effects
        ld a,(retrieved_divers)
        or a
        jr z,.effects
        call PlayRefillAudio
        jp WritePsgMixer
.effects:
        call PlayTorpedoAudio
        call PlaySecondaryAudio
        jp WritePsgMixer

PsgBeginFrame:
        ld a,$3F               ; all tone/noise sources disabled until selected
        ld (psg_mixer_shadow),a
        xor a
        ld (psg_last_volume_a),a
        ld (psg_last_volume_b),a
        ld e,a
        ld a,8
        call WRTPSG
        xor a
        ld e,a
        ld a,9
        call WRTPSG
        xor a
        ld e,a
        ld a,10
        jp WRTPSG

WritePsgMixer:
        ld a,7
        call RDPSG
        and $C0                ; preserve MSX joystick-port directions
        ld b,a
        ld a,(psg_mixer_shadow)
        and $3F
        ld (psg_last_mixer),a
        or b
        ld e,a
        ld a,7
        jp WRTPSG

PsgEnableToneA:
        ld hl,psg_mixer_shadow
        res 0,(hl)
        ret
PsgEnableToneB:
        ld hl,psg_mixer_shadow
        res 1,(hl)
        ret
PsgEnableNoiseA:
        ld hl,psg_mixer_shadow
        res 3,(hl)
        ret
PsgEnableNoiseB:
        ld hl,psg_mixer_shadow
        res 4,(hl)
        ret

; Input A is the source 0..31 AUDF divider. Four AY period units per source
; step preserve the TIA's descending pitch relationship on the MSX PSG clock.
PsgSetToneAFromDivider:
        and $1F
        inc a
        add a,a
        add a,a
        ld e,a
        xor a
        call .write_high_after_low_a
        ret
.write_high_after_low_a:
        push af
        ld a,0
        call WRTPSG
        pop af
        ld e,a
        ld a,1
        jp WRTPSG

PsgSetToneBFromDivider:
        and $1F
        inc a
        add a,a
        add a,a
        ld e,a
        xor a
        call .write_high_after_low_b
        ret
.write_high_after_low_b:
        push af
        ld a,2
        call WRTPSG
        pop af
        ld e,a
        ld a,3
        jp WRTPSG

; The NTSC TIA audio reference is color-clock/114. AUDC 12 and 15 add a
; divide-by-6 stage; the MSX PSG clock is color-clock/2 and divides tone by 16.
; Therefore the matching AY period is exactly:
;   (AUDF+1) * ((1/2)*6*114/16) = (AUDF+1) * 21.375
; Rounded table values avoid replacing Cartwright's AUDF envelope with an
; arbitrary octave shift. V34 deliberately applies this only to the two
; reported effects: AUDC 15 player torpedo and AUDC 12 shark destruction.
LoadTiaDiv6Period:
        and $1F
        add a,a
        ld l,a
        ld h,0
        ld de,TiaDiv6TonePeriods
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ret

PsgSetTiaDiv6ToneAFromDivider:
        call LoadTiaDiv6Period
        ld a,e
        ld (psg_last_period_a_low),a
        ld a,d
        ld (psg_last_period_a_high),a
        push de
        ld a,0
        call WRTPSG
        pop de
        ld e,d
        ld a,1
        jp WRTPSG

PsgSetTiaDiv6ToneBFromDivider:
        call LoadTiaDiv6Period
        ld a,e
        ld (psg_last_period_b_low),a
        ld a,d
        ld (psg_last_period_b_high),a
        push de
        ld a,2
        call WRTPSG
        pop de
        ld e,d
        ld a,3
        jp WRTPSG

; AUDC 8 clocks the TIA's 9-bit polynomial directly at 30 kHz/(AUDF+1).
; Matching that clock with an AY tone gate gives:
;   (AUDF+1) * ((1/2)*114/16) = (AUDF+1) * 3.5625
; The AY has only one faster 17-bit noise source, so two calibrated tone gates
; retain Cartwright's independent AUDF0/AUDF1 sweep while shared low-rate noise
; restores the missing POLY9 texture on baseline MSX2.
LoadTiaPoly9GatePeriod:
        and $1F
        add a,a
        ld l,a
        ld h,0
        ld de,TiaPoly9GatePeriods
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ret

PsgSetTiaPoly9GateAFromDivider:
        call LoadTiaPoly9GatePeriod
        ld a,e
        ld (psg_last_period_a_low),a
        ld a,d
        ld (psg_last_period_a_high),a
        push de
        ld a,0
        call WRTPSG
        pop de
        ld e,d
        ld a,1
        jp WRTPSG

PsgSetTiaPoly9GateBFromDivider:
        call LoadTiaPoly9GatePeriod
        ld a,e
        ld (psg_last_period_b_low),a
        ld a,d
        ld (psg_last_period_b_high),a
        push de
        ld a,2
        call WRTPSG
        pop de
        ld e,d
        ld a,3
        jp WRTPSG

PsgSetNoisePeriod:
        and $1F
        ld e,a
        ld a,6
        jp WRTPSG

PsgSetVolumeA:
        and $0F
        ld (psg_last_volume_a),a
        ld e,a
        ld a,8
        jp WRTPSG
PsgSetVolumeB:
        and $0F
        ld (psg_last_volume_b),a
        ld e,a
        ld a,9
        jp WRTPSG

PlayTorpedoAudio:
        ld a,(sfx_torpedo_counter)
        or a
        ret z
        ld (psg_value),a
        call PsgSetTiaDiv6ToneAFromDivider
        call PsgEnableToneA
        ; AUDC 15 is POLY5_DIV3 in the TIA, not a clean square wave. AY noise
        ; cannot run as slowly as the source polynomial, so gate the calibrated
        ; tone with its lowest noise clock. This preserves Cartwright's AUDF
        ; sweep while restoring the missing rough texture on baseline MSX2.
        ld a,31
        call PsgSetNoisePeriod
        call PsgEnableNoiseA
        ld a,(oxygen_value)
        cp 17
        ld a,0
        jr c,.volume_ready
        ld a,(psg_value)
        srl a
.volume_ready:
        call PsgSetVolumeA
        ld a,(frame_counter)
        and 3
        ret nz
        ld hl,sfx_torpedo_counter
        dec (hl)
        ret

PlaySecondaryAudio:
        ld a,(sfx_pickup_counter)
        or a
        jp nz,PlayPickupAudio
        ld a,(player_y)
        cp OXYGEN_DIVE_THRESHOLD
        jr c,.hits
        ld a,(oxygen_value)
        or a
        jr z,.hits
        cp 17
        jp c,PlayOxygenWarningAudio
.hits:
        ld a,(sfx_shark_hit_counter)
        or a
        jp nz,PlaySharkHitAudio
        ld a,(sfx_sub_hit_counter)
        or a
        jp nz,PlayEnemySubHitAudio
        ret

PlayPickupAudio:
        ld (psg_value),a
        ld hl,sfx_pickup_counter
        dec (hl)
        ld a,(retrieved_divers)
        cp 6
        ld a,12
        jr c,.divider_ready
        ld a,3
.divider_ready:
        call PsgSetToneBFromDivider
        call PsgEnableToneB
        ld a,(psg_value)
        srl a
        cp 16
        jr c,.volume_ready
        ld a,15
.volume_ready:
        call PsgSetVolumeB
        xor a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ret

PlayOxygenWarningAudio:
        ld a,1
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld a,8
        call PsgSetVolumeB
        ld a,(frame_counter)
        and $10
        jr nz,.noise_phase
        ld a,24
        call PsgSetToneBFromDivider
        jp PsgEnableToneB
.noise_phase:
        ld a,24
        call PsgSetNoisePeriod
        jp PsgEnableNoiseB

PlaySharkHitAudio:
        ld (psg_value),a
        ld hl,sfx_shark_hit_counter
        dec (hl)
        srl a
        call PsgSetTiaDiv6ToneBFromDivider
        call PsgEnableToneB
        ld a,(psg_value)
        srl a
        and 4
        jr z,.volume_ready
        ld b,a
        ld a,(sfx_torpedo_counter)
        or a
        ld a,b
        jr z,.volume_ready
        ; AY fixed levels are logarithmic, so source volume 4 is masked more
        ; strongly by the torpedo than on TIA. Restore the original relative
        ; balance only during overlap; the approved standalone value stays 4.
        add a,2
.volume_ready:
        jp PsgSetVolumeB

PlayEnemySubHitAudio:
        ld (psg_value),a
        ld hl,sfx_sub_hit_counter
        dec (hl)
        bit 1,a
        ld a,12
        jr z,.divider_ready
        ld a,20
.divider_ready:
        call PsgSetNoisePeriod
        call PsgEnableNoiseB
        ld a,(psg_value)
        srl a
        ; AUDV1 is four bits. The source's first 32>>1 sample is therefore
        ; zero, followed by 15, 15, 14...; preserve that wrap, not saturation.
        and $0F
        jp PsgSetVolumeB

PlayDeathAudio:
        ld a,(death_timer)
        ld (psg_value),a
        cp 15
        jr c,.second_phase
        and 1
        ld a,16
        jr z,.first_divider_ready
        ld a,3
.first_divider_ready:
        call PsgSetTiaDiv6ToneAFromDivider
        call PsgEnableToneA
        ld a,31
        call PsgSetNoisePeriod
        call PsgEnableNoiseA
        ; TIA AUDV is approximately linear while the AY/YM fixed-volume DAC is
        ; logarithmic. Directly copying Cartwright's AUDV=6 made this phase far
        ; quieter than 6/15, especially after tone/noise gating. AY level 12
        ; restores the intended weight without changing pitch or texture.
        ld a,12
        jp PsgSetVolumeA
.second_phase:
        ld a,16
        call PsgSetTiaPoly9GateAFromDivider
        call PsgEnableToneA
        ld a,31
        call PsgSetNoisePeriod
        call PsgEnableNoiseA
        ld a,(psg_value)
        ld l,a
        ld h,0
        ld de,DeathAyVolumeMap
        add hl,de
        ld a,(hl)
        jp PsgSetVolumeA

PlayRewardAudio:
        ld a,(reward_state)
        cp 1
        jr z,PlayOxygenRewardAudio
        cp 2
        jr z,PlayDiverRewardAudio
        jp PlayRefillAudio

PlayOxygenRewardAudio:
        ld a,(oxygen_value)
        and $0F
        cpl
        and $1F
        ld (psg_value),a
        call PsgSetTiaDiv6ToneAFromDivider
        call PsgEnableToneA
        ld a,(psg_value)
        sub 5
        jr nc,.second_ready
        xor a
.second_ready:
        call PsgSetTiaDiv6ToneBFromDivider
        call PsgEnableToneB
        ld a,(oxygen_value)
        or a
        ret z
        ld a,6
        call PsgSetVolumeA
        ld a,6
        jp PsgSetVolumeB

PlayDiverRewardAudio:
        ld a,(sfx_reward_counter)
        or a
        ret z
        ld (psg_value),a
        ld a,31
        call PsgSetToneAFromDivider
        call PsgEnableToneA
        ld a,6
        call PsgSetToneBFromDivider
        call PsgEnableToneB
        ld a,(psg_value)
        and $0F
        call PsgSetVolumeA
        ld a,(psg_value)
        and $0F
        call PsgSetVolumeB
        ld a,(frame_counter)
        and $0F
        ret z
        ld a,(sfx_reward_counter)
        srl a
        ld (sfx_reward_counter),a
        ret

PlayRefillAudio:
        ld a,(oxygen_value)
        srl a
        cpl
        and $1F
        ld (psg_value),a
        call PsgSetTiaPoly9GateAFromDivider
        call PsgEnableToneA
        ld a,(psg_value)
        add a,7
        and $1F
        call PsgSetTiaPoly9GateBFromDivider
        call PsgEnableToneB
        ld a,31
        call PsgSetNoisePeriod
        call PsgEnableNoiseA
        call PsgEnableNoiseB
        ld a,4
        call PsgSetVolumeA
        ld a,4
        jp PsgSetVolumeB

InitSpriteShadow:
        ld hl,SAT_SHADOW
        ld b,SPRITE_COUNT
.loop:
        ld (hl),SPRITE_HIDE_Y
        inc hl
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        djnz .loop
        ret

ReadJoystick:
        call ReadActiveStick
        cp 1
        jr z,.up
        cp 2
        jr z,.up_right
        cp 3
        jr z,.right
        cp 4
        jr z,.down_right
        cp 5
        jr z,.down
        cp 6
        jr z,.down_left
        cp 7
        jr z,.left
        cp 8
        jr z,.up_left
        jr .trigger
.up_right:
        call MoveUp
        call MoveRight
        jr .trigger
.down_right:
        call MoveDown
        call MoveRight
        jr .trigger
.down_left:
        call MoveDown
        call MoveLeft
        jr .trigger
.up_left:
        call MoveUp
        call MoveLeft
        jr .trigger
.up:
        call MoveUp
        jr .trigger
.right:
        call MoveRight
        jr .trigger
.down:
        call MoveDown
        jr .trigger
.left:
        call MoveLeft
.trigger:
        call ReadActiveTrigger
        or a
        ret z
        ld a,(torpedo_active)
        or a
        ret nz
        ld a,(player_y)
        cp PLAYER_Y_MIN+5
        ret c
        ld a,1
        ld (torpedo_active),a
        ld a,(player_facing)
        ld (torpedo_dir),a
        or a
        jr nz,.fire_left
        ld a,(player_x)
        add a,16
        ld (torpedo_x),a
        jr .fire_y
.fire_left:
        ld a,(player_x)
        cp 4
        jr nc,.left_origin_ready
        xor a
        jr .store_left_origin
.left_origin_ready:
        sub 4
.store_left_origin:
        ld (torpedo_x),a
.fire_y:
        ld a,(player_y)
        add a,3                 ; pattern row 6 appears at submarine row 9
        ld (torpedo_y),a
        ld a,16
        ld (sfx_torpedo_counter),a
        ret

; Cursor/space remain available to both alternating players.  With physical
; controllers, player 1 reads joystick port 1 and player 2 reads port 2, as the
; Atari source selects the active joystick from currentPlayerNumber.
ReadActiveStick:
        xor a
        call GTSTCK
        or a
        ret nz
        ld a,(game_mode)
        cp 2
        ld a,1
        jr nz,.read_port
        ld a,(current_player)
        inc a
.read_port:
        jp GTSTCK

ReadActiveTrigger:
        xor a
        call GTTRIG
        or a
        ret nz
        ld a,(game_mode)
        cp 2
        ld a,1
        jr nz,.read_port
        ld a,(current_player)
        inc a
.read_port:
        jp GTTRIG

MoveUp:
        ld a,(player_y)
        cp PLAYER_Y_MIN
        ret z
        dec a
        ld (player_y),a
        ret
MoveDown:
        ld a,(player_y)
        cp PLAYER_Y_MAX
        ret z
        inc a
        ld (player_y),a
        ret
MoveRight:
        xor a
        ld (player_facing),a
        ld a,(player_x)
        cp PLAYER_X_MAX
        ret z
        add a,2
        cp PLAYER_X_MAX+1
        jr c,.store
        ld a,PLAYER_X_MAX
.store:
        ld (player_x),a
        ret
MoveLeft:
        ld a,1
        ld (player_facing),a
        ld a,(player_x)
        cp PLAYER_X_MIN
        ret z
        sub 2
        jr nc,.store
        ld a,PLAYER_X_MIN
.store:
        ld (player_x),a
        ret

UpdateTorpedo:
        ld a,(torpedo_active)
        or a
        ret z
        ld a,(torpedo_dir)
        or a
        jr nz,.left
        ld a,(torpedo_x)
        add a,5
        jr c,.remove
        cp 237                  ; keep all four projectile pixels in viewport
        jr nc,.remove
        ld (torpedo_x),a
        ret
.left:
        ld a,(torpedo_x)
        sub 5
        jr c,.remove
        ld (torpedo_x),a
        ret
.remove:
        xor a
        ld (torpedo_active),a
        ld (sfx_torpedo_counter),a
        ret

UpdateAnimation:
        ld hl,frame_counter
        inc (hl)
        ; The source advances its three-round LFSR every eighth video frame.
        ; Formation reentry samples this continuously evolving seed; it does not
        ; request a new random value of its own.
        ld a,(hl)
        and 7
        call z,NextFormationRandom
        ld hl,anim_tick
        inc (hl)
        ld a,(hl)
        and 3
        ret nz
        ld a,(player_anim)
        inc a
        cp 3
        jr c,.store
        xor a
.store:
        ld (player_anim),a
        ret

; Cartwright's independent surface patrol appears at currentLevel 2. Its
; original 8-bit X wraps 0 -> 255 and remains off-screen until it falls below
; XMAX=160. Levels 2..4 step every four frames; level 5 and later every two.
UpdatePatrolSub:
        ld a,(current_level)
        cp 2
        jr nc,.active
        xor a
        ld (patrol_source_x),a
        ld (patrol_visible),a
        ret
.active:
        cp 5
        ld b,3
        jr c,.delay_ready
        ld b,1
.delay_ready:
        ld a,(frame_counter)
        and b
        jr nz,.map_position
        ld hl,patrol_source_x
        dec (hl)
        ld hl,patrol_moves
        inc (hl)
.map_position:
        ld a,(patrol_source_x)
        cp 160
        jr nc,.hide
        ; floor(sourceX * 3 / 2) maps the original 160-pixel coordinate to 240.
        ld l,a
        ld h,0
        ld e,a
        ld d,0
        add hl,hl
        add hl,de
        srl h
        rr l
        ld a,l
        ld (patrol_screen_x),a
        cp 233                  ; keep the 8-pixel sprite inside the viewport
        jr nc,.hide
        ld a,1
        ld (patrol_visible),a
        ret
.hide:
        xor a
        ld (patrol_visible),a
        ret

UpdateLanes:
        call UpdateSharkFloat
        ld ix,formation_anchor_0
        ld iy,lane_mask_0
        ld hl,lane_frac_0
        ld de,lane_dir_0
        ld a,(lane_mask_0)
        or a
        jr nz,.lane0_alive
        inc a
        ld (lane_reset_0),a
.lane0_alive:
        call UpdateOneFormation
        ld a,(lane_moved)
        ld (lane_step_0),a
        ld ix,formation_anchor_0
        ld iy,shark_x_cache_0
        ld de,lane_visible_0
        ld a,(lane_dir_0)
        ld c,a
        ld a,(lane_mask_0)
        call BuildFormationCache
        ld a,(shark_x_cache_0)
        ld (lane_x_0),a
        ld ix,formation_anchor_1
        ld iy,lane_mask_1
        ld hl,lane_frac_1
        ld de,lane_dir_1
        ld a,(lane_mask_1)
        or a
        jr nz,.lane1_alive
        inc a
        ld (lane_reset_1),a
.lane1_alive:
        call UpdateOneFormation
        ld a,(lane_moved)
        ld (lane_step_1),a
        ld ix,formation_anchor_1
        ld iy,shark_x_cache_1
        ld de,lane_visible_1
        ld a,(lane_dir_1)
        ld c,a
        ld a,(lane_mask_1)
        call BuildFormationCache
        ld a,(shark_x_cache_1)
        ld (lane_x_1),a
        ld ix,formation_anchor_2
        ld iy,lane_mask_2
        ld hl,lane_frac_2
        ld de,lane_dir_2
        ld a,(lane_mask_2)
        or a
        jr nz,.lane2_alive
        inc a
        ld (lane_reset_2),a
.lane2_alive:
        call UpdateOneFormation
        ld a,(lane_moved)
        ld (lane_step_2),a
        ld ix,formation_anchor_2
        ld iy,shark_x_cache_2
        ld de,lane_visible_2
        ld a,(lane_dir_2)
        ld c,a
        ld a,(lane_mask_2)
        call BuildFormationCache
        ld a,(shark_x_cache_2)
        ld (lane_x_2),a
        ld ix,formation_anchor_3
        ld iy,lane_mask_3
        ld hl,lane_frac_3
        ld de,lane_dir_3
        ld a,(lane_mask_3)
        or a
        jr nz,.lane3_alive
        inc a
        ld (lane_reset_3),a
.lane3_alive:
        call UpdateOneFormation
        ld a,(lane_moved)
        ld (lane_step_3),a
        ld ix,formation_anchor_3
        ld iy,shark_x_cache_3
        ld de,lane_visible_3
        ld a,(lane_dir_3)
        ld c,a
        ld a,(lane_mask_3)
        call BuildFormationCache
        ld a,(shark_x_cache_3)
        ld (lane_x_3),a
        ret

UpdateOneFormation:
        xor a
        ld (lane_moved),a
        ld a,(iy+0)
        or a
        jr nz,.formation_alive
        ; The original keeps a destroyed enemy-sub lane empty until its last
        ; BALL projectile leaves the playfield. Only then does SpawnNewObstacle
        ; rebuild that lane as sharks.
        call DeadFormationWaitsForTorpedo
        ret c
        call ResetKilledFormation
.formation_alive:
        ld a,(game_difficulty)
        add a,a
        ld b,a
        ld a,(game_difficulty)
        add a,b
        add a,18
        ld b,a
        ld a,(hl)
        add a,b
.step_loop:
        cp 32
        jr c,.store_fraction
        sub 32
        push af
        ld a,(de)
        or a
        jr nz,.step_left
        inc (ix+0)
        jr nz,.step_done
        inc (ix+1)
        jr .step_done
.step_left:
        push hl
        ld l,(ix+0)
        ld h,(ix+1)
        dec hl
        ld (ix+0),l
        ld (ix+1),h
        pop hl
.step_done:
        ld a,(lane_moved)
        inc a
        ld (lane_moved),a
        pop af
        jr .step_loop
.store_fraction:
        ld (hl),a
        call FormationHasExited
        ret nc
        call ToggleCurrentLaneType
        jp ReenterFormation

; Carry is set only after the last surviving copy is outside the viewport.
; This replaces the V19/V20 fixed close-spacing limits that could discard a
; medium-spaced survivor while it was still visibly crossing the playfield.
FormationHasExited:
        push hl
        push de
        ld a,(game_difficulty)
        and 7
        cp 4
        jr c,.close_spacing
        cp 6
        jr nc,.close_spacing
        ld c,SHARK_MED_SPACING
        jr .spacing_ready
.close_spacing:
        ld c,SHARK_CLOSE_SPACING
.spacing_ready:
        ld a,(iy+0)
        bit 2,a
        jr nz,.third_copy
        bit 1,a
        jr nz,.offset_ready
        ld c,0
        jr .offset_ready
.third_copy:
        sla c
.offset_ready:
        ld b,0
        ld l,(ix+0)
        ld h,(ix+1)
        ld a,(de)
        or a
        jr nz,.moving_left
        or a
        sbc hl,bc
        bit 7,h
        jr nz,.not_exited
        ld a,h
        or a
        jr nz,.exited
        ld a,l
        cp 233                  ; same visibility edge as MarkVisibleCopy
        jr nc,.exited
        jr .not_exited
.moving_left:
        add hl,bc
        bit 7,h
        jr z,.not_exited
        ; Any negative logical X is clipped by MarkVisibleCopy.
.exited:
        pop de
        pop hl
        scf
        ret
.not_exited:
        pop de
        pop hl
        or a                    ; clear carry
        ret

ResetKilledFormation:
        push af
        ld a,(formation_kill_resets)
        inc a
        ld (formation_kill_resets),a
        pop af
        call SetCurrentLaneShark
        ; A successful shot clears Cartwright's per-lane speed-up bit. This is
        ; repeated here because the previous rendered shark/diver latch is
        ; consumed before this zero-mask formation is rebuilt.
        call ClearCurrentLaneDiverFast
        ld a,(game_difficulty)
        and 7
        push hl
        ld hl,FormationMasks
        add a,l
        ld l,a
        jr nc,.mask_address
        inc h
.mask_address:
        ld a,(hl)
        ld (iy+0),a
        pop hl
        jp ReenterFormation

; Cartwright alternates the lane owner between shark and enemy submarine after
; a complete pass. A formation destroyed by the player restarts as a shark.
ToggleCurrentLaneType:
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        call GetCurrentLaneTypePtr
        ld c,a
        ld a,(hl)
        xor 1
        ld (hl),a
        ld b,a
        ld hl,formation_edge_resets
        inc (hl)
        ld hl,lane_reset_0
        ld e,c
        ld d,0
        add hl,de
        ld (hl),1
        ld a,b
        or a
        call nz,ClearActiveDiverForLane
        call ClearLaneAuxMotion
        call ApplyLaneColorByType
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ret

SetCurrentLaneShark:
        push af
        push bc
        push de
        push hl
        push ix
        push iy
        call GetCurrentLaneTypePtr
        ld c,a
        ld a,(hl)
        or a
        jr z,.already_shark
        xor a
        ld (hl),a
        ld b,a
        call ApplyLaneColorByType
.already_shark:
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
        pop af
        ret

; IY points to one of the four contiguous lane masks.
GetCurrentLaneIndex:
        push iy
        pop hl
        ld de,lane_mask_0
        or a
        sbc hl,de
        ld a,l
        ret

; IY points to the live mask of the lane hit/rebuilt. In the Atari source the
; swimmer's accelerated state is bit 4 of obstacleAttributes, so every player
; torpedo hit clears it even when other replicated copies survive.
ClearCurrentLaneDiverFast:
        push af
        push de
        push hl
        call GetCurrentLaneIndex
        ld e,a
        ld d,0
        ld hl,diver_fast_0
        add hl,de
        ld (hl),0
        pop hl
        pop de
        pop af
        ret

GetCurrentLaneTypePtr:
        call GetCurrentLaneIndex
        ld e,a
        ld d,0
        ld hl,lane_type_0
        add hl,de
        ret

; B=type, C=lane. Enemy submarines are white in the original; sharks retain
; the approved per-lane palette used by the existing MSX presentation.
ApplyLaneColorByType:
        ld a,c
        ld hl,LaneFirstSpriteTable
        add a,l
        ld l,a
        jr nc,.sprite_address
        inc h
.sprite_address:
        ld e,(hl)
        ld a,b
        or a
        ld a,PAL_WHITE
        jr nz,.apply
        ld a,c
        ld hl,LaneSharkColorTable
        add a,l
        ld l,a
        jr nc,.color_address
        inc h
.color_address:
        ld a,(hl)
.apply:
        call SetThreeSpriteColors
        ret

; The Atari shares the per-lane horizontal slot between the diver and enemy
; torpedo. Remove a live swimmer when its owner becomes a submarine. A rescued
; ($FF) diver-array state remains reserved, while the three motion bytes are
; reset for the new object type.
ClearActiveDiverForLane:
        ld a,c
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,diver_state_0
        add hl,de
        ld a,(hl)
        cp 1
        jr nz,.clear_fast
        ld (hl),0
.clear_fast:
        ld hl,diver_fast_0
        ld e,c
        ld d,0
        add hl,de
        ld (hl),0
        ret

; C=lane index. Clear shared X, direction and fractional motion whenever the
; owner alternates type, without releasing a rescued diver-array state.
ClearLaneAuxMotion:
        ld a,c
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,diver_state_0+1
        add hl,de
        xor a
        ld (hl),a
        inc hl
        ld (hl),a
        inc hl
        ld (hl),a
        ret

; Carry means a zero-mask enemy-sub formation still owns an in-flight torpedo.
; IY points at the current lane mask. All formation registers are preserved.
DeadFormationWaitsForTorpedo:
        push bc
        push de
        push hl
        call GetCurrentLaneIndex
        ld c,a
        ld e,a
        ld d,0
        ld hl,lane_type_0
        add hl,de
        ld a,(hl)
        or a
        jr z,.no_wait
        ld a,c
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,diver_state_0+1
        add hl,de
        ld a,(hl)
        or a
        jr z,.no_wait
        pop hl
        pop de
        pop bc
        scf
        ret
.no_wait:
        pop hl
        pop de
        pop bc
        or a
        ret

ReenterFormation:
        push hl
        push de
        ld a,(formation_random_seed)
        and 8
        jr z,.enter_left
        ld a,1
        ld (de),a
        ld hl,FORMATION_RIGHT_START
        jr .store_anchor
.enter_left:
        xor a
        ld (de),a
        ld hl,FORMATION_LEFT_START
.store_anchor:
        ld (ix+0),l
        ld (ix+1),h
        pop de
        pop hl
        xor a
        ld (hl),a
        ret

NextFormationRandom:
        push bc
        ld b,3
.round:
        ld a,(formation_random_seed)
        add a,a
        add a,a
        add a,a
        ld c,a
        ld a,(formation_random_seed)
        xor c
        add a,a
        ld a,(formation_random_seed)
        rla
        ld (formation_random_seed),a
        djnz .round
        pop bc
        ret

UpdateSharkFloat:
        ld a,(frame_counter)
        srl a
        srl a
        and 15
        ld hl,SharkFloatTable
        add a,l
        ld l,a
        jr nc,.read
        inc h
.read:
        ld a,(hl)
        ld (shark_float),a
        ret

BuildFormationCache:
        ld (build_alive_mask),a
        ld a,c
        ld (build_direction),a
        xor a
        ld (build_visible_mask),a
        ld a,(game_difficulty)
        and 7
        cp 4
        jr c,.close_spacing
        cp 6
        jr nc,.close_spacing
        ld a,SHARK_MED_SPACING
        jr .spacing_ready
.close_spacing:
        ld a,SHARK_CLOSE_SPACING
.spacing_ready:
        ld (build_spacing),a
        push de
        ld l,(ix+0)
        ld h,(ix+1)
        ld (iy+0),l
        ld a,1
        call MarkVisibleCopy
        call AdvanceFormationCopy
        ld (iy+1),l
        ld a,2
        call MarkVisibleCopy
        call AdvanceFormationCopy
        ld (iy+2),l
        ld a,4
        call MarkVisibleCopy
        pop de
        ld a,(build_visible_mask)
        ld (de),a
        ret

AdvanceFormationCopy:
        ld a,(build_spacing)
        ld e,a
        ld d,0
        ld a,(build_direction)
        or a
        jr nz,.toward_right
        or a
        sbc hl,de
        ret
.toward_right:
        add hl,de
        ret

MarkVisibleCopy:
        ld b,a
        ld a,h
        or a
        ret nz
        ld a,l
        cp 233
        ret nc
        ld a,(build_alive_mask)
        and b
        ret z
        ld a,(build_visible_mask)
        or b
        ld (build_visible_mask),a
        ret

; One source-owned enemy torpedo can exist in each submarine lane. The lane's
; diver horizontal/fraction bytes are reused exactly as the Atari arrays are:
; sharks interpret them as swimmer state, submarines as BALL projectile state.
UpdateEnemyTorpedoes:
        ld ix,diver_state_0
        ld iy,lane_mask_0
        ld hl,shark_x_cache_0
        ld a,(lane_type_0)
        or a
        jr z,.lane1
        ld a,(lane_visible_0)
        ld d,a
        ld a,(lane_dir_0)
        ld c,a
        call UpdateOneEnemyTorpedo
.lane1:
        ld ix,diver_state_1
        ld iy,lane_mask_1
        ld hl,shark_x_cache_1
        ld a,(lane_type_1)
        or a
        jr z,.lane2
        ld a,(lane_visible_1)
        ld d,a
        ld a,(lane_dir_1)
        ld c,a
        call UpdateOneEnemyTorpedo
.lane2:
        ld ix,diver_state_2
        ld iy,lane_mask_2
        ld hl,shark_x_cache_2
        ld a,(lane_type_2)
        or a
        jr z,.lane3
        ld a,(lane_visible_2)
        ld d,a
        ld a,(lane_dir_2)
        ld c,a
        call UpdateOneEnemyTorpedo
.lane3:
        ld ix,diver_state_3
        ld iy,lane_mask_3
        ld hl,shark_x_cache_3
        ld a,(lane_type_3)
        or a
        ret z
        ld a,(lane_visible_3)
        ld d,a
        ld a,(lane_dir_3)
        ld c,a
        jp UpdateOneEnemyTorpedo

; IX=shared lane state, IY=survivor mask, HL=three copy X values,
; C=formation direction (0 right, 1 left), D=visible copy mask.
UpdateOneEnemyTorpedo:
        ld a,(ix+1)
        or a
        jr nz,.move
        ; The source chooses the foremost surviving replicated submarine and
        ; fires only while that copy is inside its central 39..126 gate. The
        ; gate is scaled by 1.5 for this 240-pixel playfield.
        ld a,(iy+0)
        and d
        ret z
        bit 0,a
        jr nz,.candidate
        inc hl
        bit 1,a
        jr nz,.candidate
        inc hl
.candidate:
        ld a,(hl)
        cp ENEMY_TORPEDO_MIN_X
        ret c
        cp ENEMY_TORPEDO_MAX_X
        ret nc
        ld (ix+1),a
        ld (ix+2),c
        ld (ix+3),0
        ld a,(enemy_torpedo_spawns)
        inc a
        ld (enemy_torpedo_spawns),a
.move:
        ; Original speed is (difficulty+16)/16 Atari pixels per frame.
        ; 3*difficulty+48 over 32 preserves that rate after the 1.5x scale.
        ld a,(game_difficulty)
        add a,a
        ld b,a
        ld a,(game_difficulty)
        add a,b
        add a,48
        ld b,a
        ld a,(ix+3)
        add a,b
.step_loop:
        cp 32
        jr c,.store_fraction
        sub 32
        push af
        ld a,(ix+2)
        or a
        jr nz,.step_left
        ld a,(ix+1)
        cp X_MAX
        jr nc,.leave_pop
        inc a
        ld (ix+1),a
        jr .step_done
.step_left:
        ld a,(ix+1)
        or a
        jr z,.leave_pop
        dec a
        jr z,.leave_pop
        ld (ix+1),a
.step_done:
        pop af
        jr .step_loop
.leave_pop:
        pop af
.leave:
        xor a
        ld (ix+1),a
        ld (ix+3),a
        ret
.store_fraction:
        ld (ix+3),a
        ret

; Source model: state 0=eligible/absent, 1=active, $FF=rescued. A swimmer
; starts at half formation speed and switches to full speed after shark contact.
UpdateDiver:
        ld ix,diver_state_0
        ld de,diver_fast_0
        ld a,(lane_step_0)
        ld (active_lane_step),a
        ld a,(lane_type_0)
        or a
        jr nz,.move_lane1
        ; The original diver has no private direction: it reads the direction
        ; of its lane owner every frame. Preserve the struct byte for rendering
        ; and enemy-torpedo reuse, but synchronize it while the owner is a shark.
        ld a,(lane_dir_0)
        ld (ix+2),a
        call UpdateOneDiver
.move_lane1:
        ld ix,diver_state_1
        ld de,diver_fast_1
        ld a,(lane_step_1)
        ld (active_lane_step),a
        ld a,(lane_type_1)
        or a
        jr nz,.move_lane2
        ld a,(lane_dir_1)
        ld (ix+2),a
        call UpdateOneDiver
.move_lane2:
        ld ix,diver_state_2
        ld de,diver_fast_2
        ld a,(lane_step_2)
        ld (active_lane_step),a
        ld a,(lane_type_2)
        or a
        jr nz,.move_lane3
        ld a,(lane_dir_2)
        ld (ix+2),a
        call UpdateOneDiver
.move_lane3:
        ld ix,diver_state_3
        ld de,diver_fast_3
        ld a,(lane_step_3)
        ld (active_lane_step),a
        ld a,(lane_type_3)
        or a
        jr nz,.spawn_checks
        ld a,(lane_dir_3)
        ld (ix+2),a
        call UpdateOneDiver
.spawn_checks:
        ld ix,diver_state_0
        ld iy,lane_reset_0
        ld de,diver_fast_0
        ld a,(lane_dir_0)
        ld b,a
        ld a,(lane_type_0)
        or a
        jr nz,.spawn_lane1
        ld a,b
        call MaybeSpawnLaneDiver
.spawn_lane1:
        ld ix,diver_state_1
        ld iy,lane_reset_1
        ld de,diver_fast_1
        ld a,(lane_dir_1)
        ld b,a
        ld a,(lane_type_1)
        or a
        jr nz,.spawn_lane2
        ld a,b
        call MaybeSpawnLaneDiver
.spawn_lane2:
        ld ix,diver_state_2
        ld iy,lane_reset_2
        ld de,diver_fast_2
        ld a,(lane_dir_2)
        ld b,a
        ld a,(lane_type_2)
        or a
        jr nz,.spawn_lane3
        ld a,b
        call MaybeSpawnLaneDiver
.spawn_lane3:
        ld ix,diver_state_3
        ld iy,lane_reset_3
        ld de,diver_fast_3
        ld a,(lane_dir_3)
        ld b,a
        ld a,(lane_type_3)
        or a
        jr nz,.interactions
        ld a,b
        call MaybeSpawnLaneDiver
.interactions:
        ret

UpdateOneDiver:
        ld a,(ix+0)
        cp 1
        ret nz
        ld a,(de)
        or a
        jr z,.half_speed
        ; Cartwright reuses tmpObstacleSpeed after the TIA shark/diver latch.
        ; Apply the parent's exact integer displacement for this frame instead
        ; of integrating a second fractional phase with merely the same average.
        xor a
        ld (ix+3),a
        ld a,(active_lane_step)
        or a
        ret z
        ld b,a
.matched_step:
        ld a,(ix+2)
        or a
        jr nz,.matched_left
        ld a,(ix+1)
        cp X_MAX
        jr nc,.leave
        inc a
        ld (ix+1),a
        djnz .matched_step
        ret
.matched_left:
        ld a,(ix+1)
        or a
        jr z,.leave
        dec a
        jr z,.leave
        ld (ix+1),a
        djnz .matched_step
        ret
.half_speed:
        ld a,(game_difficulty)
        add a,a
        ld b,a
        ld a,(game_difficulty)
        add a,b
        add a,18                ; half speed in 1/64 MSX pixels
        ld b,a
        ld a,(ix+3)
        add a,b
        cp 64
        jr c,.store_fraction
        sub 64
        ld (ix+3),a
        ld a,(ix+2)
        or a
        jr nz,.left
        ld a,(ix+1)
        cp X_MAX
        jr nc,.leave
        inc a
        ld (ix+1),a
        ret
.left:
        ld a,(ix+1)
        or a
        jr z,.leave
        dec a
        ld (ix+1),a
        ret
.store_fraction:
        ld (ix+3),a
        ret
.leave:
        xor a
        ld (ix+0),a
        ld (de),a
        ret

MaybeSpawnLaneDiver:
        ld b,a
        ld a,(iy+0)
        or a
        ret z
        xor a
        ld (iy+0),a
        ld a,(ix+0)
        cp $FF
        ret z
        or a
        ret nz
        ld a,(formation_random_seed)
        cp 80
        ret c
        ld a,b
        or a
        jr nz,.left_entry
        ld (ix+1),0
        jr .activate
.left_entry:
        ; The 2600 uses X=0 as a sentinel, then reloads XMAX before the first
        ; leftward step. Starting at scaled XMAX preserves the clipped entry.
        ld (ix+1),X_MAX
.activate:
        ld (ix+2),b
        ld (ix+3),0
        xor a
        ld (de),a
        inc a
        ld (ix+0),1
        ret

; The TIA sets the shark/diver collision latch from the pixels emitted by the
; kernel. Reconstruct the same opaque-pixel test before this frame's movement.
CheckSharkDiverInteractions:
        ld a,LANE0_Y+DIVER_Y_OFFSET
        ld (interaction_diver_y),a
        ld a,(shark_float)
        add a,LANE0_Y
        ld (interaction_shark_y),a
        ld a,(lane_dir_0)
        ld (interaction_shark_dir),a
        ld ix,diver_state_0
        ld iy,lane_visible_0
        ld hl,shark_x_cache_0
        ld de,diver_fast_0
        ld a,(lane_type_0)
        or a
        call z,CheckOneSharkDiver
        ld a,LANE1_Y+DIVER_Y_OFFSET
        ld (interaction_diver_y),a
        ld a,(shark_float)
        add a,LANE1_Y
        ld (interaction_shark_y),a
        ld a,(lane_dir_1)
        ld (interaction_shark_dir),a
        ld ix,diver_state_1
        ld iy,lane_visible_1
        ld hl,shark_x_cache_1
        ld de,diver_fast_1
        ld a,(lane_type_1)
        or a
        call z,CheckOneSharkDiver
        ld a,LANE2_Y+DIVER_Y_OFFSET
        ld (interaction_diver_y),a
        ld a,(shark_float)
        add a,LANE2_Y
        ld (interaction_shark_y),a
        ld a,(lane_dir_2)
        ld (interaction_shark_dir),a
        ld ix,diver_state_2
        ld iy,lane_visible_2
        ld hl,shark_x_cache_2
        ld de,diver_fast_2
        ld a,(lane_type_2)
        or a
        call z,CheckOneSharkDiver
        ld a,LANE3_Y+DIVER_Y_OFFSET
        ld (interaction_diver_y),a
        ld a,(shark_float)
        add a,LANE3_Y
        ld (interaction_shark_y),a
        ld a,(lane_dir_3)
        ld (interaction_shark_dir),a
        ld ix,diver_state_3
        ld iy,lane_visible_3
        ld hl,shark_x_cache_3
        ld de,diver_fast_3
        ld a,(lane_type_3)
        or a
        ret nz
        jp CheckOneSharkDiver

CheckOneSharkDiver:
        ld a,(ix+0)
        cp 1
        ret nz
        ; Cartwright only accepts the TIA latch while the swimmer is inside
        ; XMIN+8..XMAX-9. Ignore edge-entry overlap exactly as the source does.
        ld a,(ix+1)
        cp DIVER_INTERACTION_MIN_X
        ret c
        cp DIVER_INTERACTION_MAX_X
        ret nc
        ld a,(de)
        or a
        ret nz
        bit 0,(iy+0)
        jr z,.copy1
        ld a,(hl)
        call SharkPixelsTouchDiver
        jr c,.flee
.copy1:
        inc hl
        bit 1,(iy+0)
        jr z,.copy2
        ld a,(hl)
        call SharkPixelsTouchDiver
        jr c,.flee
.copy2:
        inc hl
        bit 2,(iy+0)
        ret z
        ld a,(hl)
        call SharkPixelsTouchDiver
        ret nc
.flee:
        ld a,1
        ld (de),a
        ret

; A=shark X, IX=lane swimmer. Carry is returned only for an opaque-pixel hit
; between the exact animated 8-pixel patterns at their rendered vertical rows.
SharkPixelsTouchDiver:
        ld (pixel_shark_x),a
        ld b,a
        ld a,(ix+1)
        add a,7
        cp b
        jp c,.quick_miss
        ld a,b
        add a,8
        ld b,a
        ld a,(ix+1)
        cp b
        jp nc,.quick_miss
        ld a,(ix+1)
        ld (interaction_diver_x),a
        push ix
        push iy
        push bc
        push de
        push hl
        ld a,(interaction_diver_y)
        ld b,a
        ld a,(interaction_shark_y)
        ld c,a
        cp b
        jr nc,.shark_below
        ld d,b
        jr .have_start
.shark_below:
        ld d,c
.have_start:
        ld a,d
        sub b
        ld (pixel_player_row),a
        cp 16
        jp nc,.miss
        ld a,d
        sub c
        ld (pixel_shark_row),a
        cp 16
        jp nc,.miss
        ld b,a
        ld a,16
        sub b
        ld c,a
        ld a,(pixel_player_row)
        ld b,a
        ld a,16
        sub b
        cp c
        jr c,.rows_ready
        ld a,c
.rows_ready:
        ld (pixel_rows),a
        or a
        jp z,.miss
        ld hl,DiverRight0
        ld a,(interaction_shark_dir)
        or a
        jr z,.diver_direction_ready
        ld hl,DiverLeft0
.diver_direction_ready:
        ld a,(frame_counter)
        srl a
        srl a
        srl a
.diver_modulo_three:
        cp 3
        jr c,.diver_frame_ready
        sub 3
        jr .diver_modulo_three
.diver_frame_ready:
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld a,(pixel_player_row)
        ld e,a
        add hl,de
        push hl
        pop ix
        ld hl,SharkRight0
        ld a,(interaction_shark_dir)
        or a
        jr z,.shark_direction_ready
        ld hl,SharkLeft0
.shark_direction_ready:
        ld a,(frame_counter)
        and 8
        jr z,.shark_frame_ready
        ld de,32
        add hl,de
.shark_frame_ready:
        ld a,(pixel_shark_row)
        ld e,a
        ld d,0
        add hl,de
        push hl
        pop iy
.row_loop:
        ld a,(iy+0)
        ld (pixel_shark_bits),a
        ld a,(pixel_shark_x)
        ld (pixel_global_x),a
        ld a,8
        ld (pixel_bit_count),a
.bit_loop:
        ld a,(pixel_shark_bits)
        add a,a
        ld (pixel_shark_bits),a
        jr nc,.next_bit
        ld a,(pixel_global_x)
        ld b,a
        ld a,(interaction_diver_x)
        ld c,a
        ld a,b
        sub c
        jr c,.next_bit
        cp 8
        jr nc,.next_bit
        ld (pixel_local_x),a
        ld c,$80
        and 7
        jr z,.mask_ready
        ld b,a
.shift_mask:
        srl c
        djnz .shift_mask
.mask_ready:
        ld a,(ix+0)
        and c
        jr nz,.hit
.next_bit:
        ld a,(pixel_global_x)
        inc a
        ld (pixel_global_x),a
        ld a,(pixel_bit_count)
        dec a
        ld (pixel_bit_count),a
        jr nz,.bit_loop
        inc ix
        inc iy
        ld a,(pixel_rows)
        dec a
        ld (pixel_rows),a
        jr nz,.row_loop
.miss:
        pop hl
        pop de
        pop bc
        pop iy
        pop ix
        or a
        ret
.hit:
        pop hl
        pop de
        pop bc
        pop iy
        pop ix
        scf
        ret
.quick_miss:
        or a
        ret

; Functional V2 collision pass. Each replicated shark is an independent target.
CheckCollisions:
        ld a,(torpedo_active)
        or a
        jr z,.player
        ld hl,shark_x_cache_0
        ld ix,lane_visible_0
        ld iy,lane_mask_0
        ld a,(lane_type_0)
        ld c,a
        ld b,LANE0_TORPEDO_BASE_Y
        ld a,(torpedo_y)
        call CheckTorpedoLaneY
.torp_lane1:
        ld a,(torpedo_active)
        or a
        jr z,.player
        ld hl,shark_x_cache_1
        ld ix,lane_visible_1
        ld iy,lane_mask_1
        ld a,(lane_type_1)
        ld c,a
        ld b,LANE1_TORPEDO_BASE_Y
        ld a,(torpedo_y)
        call CheckTorpedoLaneY
.torp_lane2:
        ld a,(torpedo_active)
        or a
        jr z,.player
        ld hl,shark_x_cache_2
        ld ix,lane_visible_2
        ld iy,lane_mask_2
        ld a,(lane_type_2)
        ld c,a
        ld b,LANE2_TORPEDO_BASE_Y
        ld a,(torpedo_y)
        call CheckTorpedoLaneY
.torp_lane3:
        ld a,(torpedo_active)
        or a
        jr z,.player
        ld hl,shark_x_cache_3
        ld ix,lane_visible_3
        ld iy,lane_mask_3
        ld a,(lane_type_3)
        ld c,a
        ld b,LANE3_TORPEDO_BASE_Y
        ld a,(torpedo_y)
        call CheckTorpedoLaneY
.player:
        call CheckDiverPickup
        ld a,(player_grace)
        or a
        jr z,.enemy_torpedoes
        dec a
        ld (player_grace),a
        xor a
        ld (collision_confirm),a
        ld (collision_seen),a
        ret
.enemy_torpedoes:
        call CheckEnemyTorpedoHits
        ret c
        call CheckPatrolSubHit
        ret c
        jp CheckPlayerLive

; The patrol is the original P1 surface hazard and therefore collides against
; the protagonist's opaque body on the first frame, without the shark fringe
; confirmation filter. It cannot be destroyed by the player's torpedo.
CheckPatrolSubHit:
        ld a,(patrol_visible)
        or a
        ret z
        ld a,1
        ld (collision_obstacle_type),a
        ld (collision_shark_dir),a   ; patrol is always reflected / left-facing
        ld a,PATROL_SUB_LOGICAL_Y
        ld (collision_shark_y),a
        ld a,(patrol_screen_x)
        call PlayerHitsX
        ret nc
        xor a
        ld (patrol_source_x),a
        ld (patrol_visible),a
        ld a,(patrol_hits)
        inc a
        ld (patrol_hits),a
        ld a,4
        ld (death_reason),a
        call BeginPlayerDeath
        scf
        ret

; A lane BALL is mutually exclusive: a shark lane owns a swimmer and an enemy-
; submarine lane owns a torpedo. Unlike obstacle contact, the original kills on
; the first confirmed BALL/pixel collision, so no two-frame fringe filter is
; applied here.
CheckEnemyTorpedoHits:
        ld ix,diver_state_0
        ld b,LANE0_Y+ENEMY_TORPEDO_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
        ld a,(lane_type_0)
        or a
        call nz,CheckOneEnemyTorpedoHit
        ret c
        ld ix,diver_state_1
        ld b,LANE1_Y+ENEMY_TORPEDO_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
        ld a,(lane_type_1)
        or a
        call nz,CheckOneEnemyTorpedoHit
        ret c
        ld ix,diver_state_2
        ld b,LANE2_Y+ENEMY_TORPEDO_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
        ld a,(lane_type_2)
        or a
        call nz,CheckOneEnemyTorpedoHit
        ret c
        ld ix,diver_state_3
        ld b,LANE3_Y+ENEMY_TORPEDO_Y_OFFSET-PLAYER_SCREEN_Y_OFFSET
        ld a,(lane_type_3)
        or a
        call nz,CheckOneEnemyTorpedoHit
        ret

; IX=shared lane state, B=logical top Y.
CheckOneEnemyTorpedoHit:
        ld a,(ix+1)
        or a
        ret z
        ld c,(ix+2)
        call EnemyTorpedoHitsPlayer
        ret nc
        xor a
        ld (ix+1),a
        ld (ix+3),a
        ld a,(enemy_torpedo_hits)
        inc a
        ld (enemy_torpedo_hits),a
        ld a,3
        ld (death_reason),a
        call BeginPlayerDeath
        scf
        ret

; A=enemy torpedo X, B=logical top Y, C=direction. Test only the eight opaque
; pixels reconstructed from the TIA BALL: $3C on row 0 and a reflected $0F on
; row 3. The protagonist's decorative outline is deliberately excluded.
EnemyTorpedoHitsPlayer:
        ld (pixel_shark_x),a
        ld a,b
        ld (collision_shark_y),a
        ld a,c
        ld (collision_shark_dir),a
        push ix
        ld d,$3C
        ld a,(collision_shark_y)
        call EnemyTorpedoRowHitsPlayer
        jr c,.hit
        ld d,$0F
        ld a,(collision_shark_dir)
        or a
        jr z,.last_row_ready
        ld d,$F0
.last_row_ready:
        ld a,(collision_shark_y)
        add a,3
        call EnemyTorpedoRowHitsPlayer
        jr c,.hit
        pop ix
        or a
        ret
.hit:
        pop ix
        scf
        ret

; A=global logical Y, D=torpedo row bits. Carry means an opaque player pixel.
EnemyTorpedoRowHitsPlayer:
        ld (pixel_shark_bits),a    ; temporarily preserve global Y
        ld a,d
        ld (pixel_rows),a
        ld a,(pixel_shark_bits)
        ld b,a
        ld a,(player_y)
        ld c,a
        ld a,b
        sub c
        jr nc,.row_not_above
        or a                    ; vertical miss must return carry clear
        ret
.row_not_above:
        cp 16
        ret nc
        ld e,a
        ld d,0
        ld hl,SubRight0
        ld a,(player_facing)
        or a
        jr z,.player_base
        ld hl,SubLeft0
.player_base:
        ld a,(player_anim)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        add hl,bc
        add hl,de
        push hl
        pop ix
        ld a,(pixel_rows)
        ld (pixel_shark_bits),a
        ld a,(pixel_shark_x)
        ld (pixel_global_x),a
        ld a,8
        ld (pixel_bit_count),a
.bit_loop:
        ld a,(pixel_shark_bits)
        add a,a
        ld (pixel_shark_bits),a
        jr nc,.next_bit
        ld a,(pixel_global_x)
        ld b,a
        ld a,(player_x)
        ld c,a
        ld a,b
        sub c
        jr c,.next_bit
        cp 16
        jr nc,.next_bit
        ld (pixel_local_x),a
        ld c,$80
        and 7
        jr z,.mask_ready
        ld b,a
.shift_mask:
        srl c
        djnz .shift_mask
.mask_ready:
        ld a,(pixel_local_x)
        cp 8
        ld a,(ix+0)
        jr c,.test_pixel
        ld a,(ix+16)
.test_pixel:
        and c
        jr nz,.hit
.next_bit:
        ld a,(pixel_global_x)
        inc a
        ld (pixel_global_x),a
        ld a,(pixel_bit_count)
        dec a
        ld (pixel_bit_count),a
        jr nz,.bit_loop
        or a
        ret
.hit:
        scf
        ret

; Check the four lane-owned swimmers. A contains each logical top Y.
CheckDiverPickup:
        ld ix,diver_state_0
        ld a,DIVER0_LOGICAL_Y
        call CheckOneDiverPickup
        ld ix,diver_state_1
        ld a,DIVER1_LOGICAL_Y
        call CheckOneDiverPickup
        ld ix,diver_state_2
        ld a,DIVER2_LOGICAL_Y
        call CheckOneDiverPickup
        ld ix,diver_state_3
        ld a,DIVER3_LOGICAL_Y
        call CheckOneDiverPickup
        jp ResetRescuedDiverSlots

CheckOneDiverPickup:
        ld c,a
        ld a,(ix+0)
        cp 1
        ret nz
        ld a,(retrieved_divers)
        cp 6
        ret nc
        ld a,(player_y)
        add a,11
        ld b,a
        ld a,c
        inc a
        cp b
        ret nc
        ld a,c
        add a,13
        ld b,a
        ld a,(player_y)
        add a,5
        cp b
        ret nc
        ld a,(player_x)
        add a,13
        ld b,a
        ld a,(ix+1)
        inc a
        cp b
        ret nc
        ld a,(ix+1)
        add a,7
        ld b,a
        ld a,(player_x)
        add a,2
        cp b
        ret nc
        ld a,$FF
        ld (ix+0),a
        ld hl,retrieved_divers
        inc (hl)
        ld a,23
        ld (sfx_pickup_counter),a
        xor a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld a,(hl)
        cp 6
        jr nz,.pickup_ready
        ld a,1
        ld (hud_diver_blink_active),a
.pickup_ready:
        call DrawRetrievedDivers
        scf
        ret

ResetRescuedDiverSlots:
        ld a,(diver_state_0)
        inc a
        ret nz
        ld a,(diver_state_1)
        inc a
        ret nz
        ld a,(diver_state_2)
        inc a
        ret nz
        ld a,(diver_state_3)
        inc a
        ret nz
        xor a
        ld (diver_state_0),a
        ld (diver_state_1),a
        ld (diver_state_2),a
        ld (diver_state_3),a
        ret
CheckPlayerLive:
        ; A rescued diver grants a clear delivery corridor through the first
        ; lane. This prevents a shark fringe from converting surfacing into a
        ; center respawn before oxygen service begins.
        ld a,(retrieved_divers)
        or a
        jr z,.check_lanes
        ld a,(player_y)
        cp SURFACE_SAFE_Y
        jr nc,.check_lanes
        xor a
        ld (collision_confirm),a
        ld (collision_seen),a
        ret
.check_lanes:
        xor a
        ld (collision_seen),a
        ld a,(lane_type_0)
        ld (collision_obstacle_type),a
        or a
        ld a,LANE0_Y-PLAYER_SCREEN_Y_OFFSET
        jr nz,.lane0_y_ready
        ld a,(shark_float)
        add a,LANE0_Y-PLAYER_SCREEN_Y_OFFSET
.lane0_y_ready:
        ld (collision_shark_y),a
        ld a,(lane_dir_0)
        ld (collision_shark_dir),a
        ld hl,shark_x_cache_0
        ld ix,lane_visible_0
        call CheckPlayerLane
.player_lane1:
        ld a,(lane_type_1)
        ld (collision_obstacle_type),a
        or a
        ld a,LANE1_Y-PLAYER_SCREEN_Y_OFFSET
        jr nz,.lane1_y_ready
        ld a,(shark_float)
        add a,LANE1_Y-PLAYER_SCREEN_Y_OFFSET
.lane1_y_ready:
        ld (collision_shark_y),a
        ld a,(lane_dir_1)
        ld (collision_shark_dir),a
        ld hl,shark_x_cache_1
        ld ix,lane_visible_1
        call CheckPlayerLane
.player_lane2:
        ld a,(lane_type_2)
        ld (collision_obstacle_type),a
        or a
        ld a,LANE2_Y-PLAYER_SCREEN_Y_OFFSET
        jr nz,.lane2_y_ready
        ld a,(shark_float)
        add a,LANE2_Y-PLAYER_SCREEN_Y_OFFSET
.lane2_y_ready:
        ld (collision_shark_y),a
        ld a,(lane_dir_2)
        ld (collision_shark_dir),a
        ld hl,shark_x_cache_2
        ld ix,lane_visible_2
        call CheckPlayerLane
.player_lane3:
        ld a,(lane_type_3)
        ld (collision_obstacle_type),a
        or a
        ld a,LANE3_Y-PLAYER_SCREEN_Y_OFFSET
        jr nz,.lane3_y_ready
        ld a,(shark_float)
        add a,LANE3_Y-PLAYER_SCREEN_Y_OFFSET
.lane3_y_ready:
        ld (collision_shark_y),a
        ld a,(lane_dir_3)
        ld (collision_shark_dir),a
        ld hl,shark_x_cache_3
        ld ix,lane_visible_3
        call CheckPlayerLane
        jr FinalizePlayerCollision

FinalizePlayerCollision:
        ld a,(collision_seen)
        or a
        ret nz
        xor a
        ld (collision_confirm),a
        ret

; A is the torpedo sprite top Y, B is the lane's shark-aligned projectile Y,
; and C is the live obstacle type. The MSX torpedo occupies pattern row 6.
; Sharks use source-art rows 0..6 and follow their visible vertical float.
; Enemy submarines are fixed and use source-art rows 2..12; V24 incorrectly
; retained the shark interval and rejected valid hits on their lower body.
CheckTorpedoLaneY:
        ld d,a
        ld a,c
        or a
        jr nz,.enemy_sub
        ld a,(shark_float)
        add a,b
        ld e,a
        ld a,SHARK_VISIBLE_ROWS
        jr .have_range
.enemy_sub:
        ld a,b
        add a,ENEMY_SUB_FIRST_ROW
        ld e,a
        ld a,ENEMY_SUB_VISIBLE_ROWS
.have_range:
        ld b,a
        ld a,d
        cp e
        ret c
        ld a,e
        add a,b
        ld e,a
        ld a,d
        cp e
        ret nc
        jp CheckTorpedoLane

CheckTorpedoLane:
        bit 0,(ix+0)
        jr z,.copy1
        ld a,(hl)
        call TorpedoHitsX
        jr c,.hit0
.copy1:
        inc hl
        bit 1,(ix+0)
        jr z,.copy2
        ld a,(hl)
        call TorpedoHitsX
        jr c,.hit1
.copy2:
        inc hl
        bit 2,(ix+0)
        ret z
        ld a,(hl)
        call TorpedoHitsX
        ret nc
        res 2,(iy+0)
        jr .remove
.hit0:
        res 0,(iy+0)
        jr .remove
.hit1:
        res 1,(iy+0)
.remove:
        call ClearCurrentLaneDiverFast
        ld a,c
        or a
        jr nz,.enemy_sub_sound
        ld a,16
        ld (sfx_shark_hit_counter),a
        jr .hit_sound_ready
.enemy_sub_sound:
        ld a,32
        ld (sfx_sub_hit_counter),a
.hit_sound_ready:
        ld a,(formation_shot_count)
        inc a
        ld (formation_shot_count),a
        ld a,(current_point_value)
        call IncrementScoreBcd
        call DrawScoreValue
        xor a
        ld (torpedo_active),a
        ld (sfx_torpedo_counter),a
        ret

; A=shark X. Carry means the four-pixel projectile overlaps its eight-pixel body.
TorpedoHitsX:
        cp 233                  ; renderer hides this clipped border interval
        ret nc
        ld b,a
        ld a,(torpedo_x)
        add a,3
        cp b
        jr nc,.left_edge_clear
        or a                    ; projectile is left of target: definite miss
        ret
.left_edge_clear:
        ld a,b
        add a,8
        ld b,a
        ld a,(torpedo_x)
        cp b
        ret nc
        scf
        ret

CheckPlayerLane:
        bit 0,(ix+0)
        jr z,.copy1
        ld a,(hl)
        push hl
        call PlayerHitsX
        pop hl
        jr c,ResetPlayerAfterCollision
.copy1:
        inc hl
        bit 1,(ix+0)
        jr z,.copy2
        ld a,(hl)
        push hl
        call PlayerHitsX
        pop hl
        jr c,ResetPlayerAfterCollision
.copy2:
        inc hl
        bit 2,(ix+0)
        ret z
        ld a,(hl)
        call PlayerHitsX
        ret nc
ResetPlayerAfterCollision:
        ld a,(collision_seen)
        or a
        ret nz                  ; never count two sharks in the same frame
        ld a,1
        ld (collision_seen),a
        ld a,(collision_confirm)
        or a
        jr z,.arm
        ld a,1
        ld (death_reason),a
        xor a
        ld (collision_confirm),a
        jp BeginPlayerDeath
.arm:
        ld a,1
        ld (collision_confirm),a
        ret

ResetPlayerAfterDeath:
        ; Cartwright removes one rescued swimmer from the player who died before
        ; considering a two-player handoff.
        ld a,(retrieved_divers)
        or a
        jr z,.no_diver_loss
        dec a
        ld (retrieved_divers),a
        call DrawRetrievedDivers
.no_diver_loss:
        ld a,(game_mode)
        cp 2
        jr nz,.one_player
        ; Game over only when both active and waiting reserve counts are zero.
        ld a,(reserve_subs)
        ld b,a
        ld a,(reserve_player_subs)
        or b
        jr z,.game_over
        call SelectNextPlayerAfterDeath
        call ResetPlayfieldForPlayerTurn
        call ClearSubClubBanner
        xor a
        ld (sub_club_timer_low),a
        ld (sub_club_timer_high),a
        dec a
        ld (sub_club_last_phase),a
        jr .respawn
.one_player:
        ; The active submarine is separate from Cartwright's three reserves.
        ; Consume one reserve only after the destruction animation completes.
        ld a,(reserve_subs)
        or a
        jr z,.game_over
        dec a
        ld (reserve_subs),a
.respawn:
        ld a,112
        ld (player_x),a
        ld a,13
        ld (player_y),a
        xor a
        ld (torpedo_active),a
        ld (sfx_torpedo_counter),a
        ld (sfx_pickup_counter),a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld (collision_confirm),a
        ld (collision_seen),a
        ld (death_timer),a
        ld a,90
        ld (player_grace),a
        ld a,MAX_OXYGEN_VALUE
        ld (oxygen_value),a
        call UpdateCurrentPointValue
        jp ApplyCurrentPlayerPresentation
.game_over:
        xor a
        ld (death_timer),a
        ld (torpedo_active),a
        ld a,1
        ld (game_over),a
        ret

; Exact DecrementReservedSubs rule: try the waiting player first. If that
; player has no reserve, swap back and consume the current player's reserve.
SelectNextPlayerAfterDeath:
        call SwapPlayerVariables
        ld a,(reserve_subs)
        or a
        jr nz,.consume
        call SwapPlayerVariables
.consume:
        ld a,(reserve_subs)
        dec a
        ld (reserve_subs),a
        ret

; Swap the seven bytes at currentPlayerVariables/reservePlayerVariables in the
; 1983 source, plus the independent V38 Sub Club latch.
SwapPlayerVariables:
        ld a,(score_bcd_high)
        ld b,a
        ld a,(reserve_score_high)
        ld (score_bcd_high),a
        ld a,b
        ld (reserve_score_high),a
        ld a,(score_bcd_mid)
        ld b,a
        ld a,(reserve_score_mid)
        ld (score_bcd_mid),a
        ld a,b
        ld (reserve_score_mid),a
        ld a,(score_bcd_low)
        ld b,a
        ld a,(reserve_score_low)
        ld (score_bcd_low),a
        ld a,b
        ld (reserve_score_low),a
        ld a,(reserve_subs)
        ld b,a
        ld a,(reserve_player_subs)
        ld (reserve_subs),a
        ld a,b
        ld (reserve_player_subs),a
        ld a,(current_level)
        ld b,a
        ld a,(reserve_current_level)
        ld (current_level),a
        ld a,b
        ld (reserve_current_level),a
        ld a,(game_difficulty)
        ld b,a
        ld a,(reserve_difficulty)
        ld (game_difficulty),a
        ld a,b
        ld (reserve_difficulty),a
        ld a,(retrieved_divers)
        ld b,a
        ld a,(reserve_divers)
        ld (retrieved_divers),a
        ld a,b
        ld (reserve_divers),a
        ld a,(sub_club_claimed)
        ld b,a
        ld a,(reserve_sub_club)
        ld (sub_club_claimed),a
        ld a,b
        ld (reserve_sub_club),a
        ld a,(current_player)
        xor 1
        ld (current_player),a
        ld hl,player_switch_count
        inc (hl)
        ret

; Reset the shared TIA playfield positions between alternating turns without
; inventing per-player enemy worlds. Diver-array state remains global, while
; the shared X/fraction bytes and projectiles are removed as in the source.
ResetPlayfieldForPlayerTurn:
        xor a
        ld (lane_mask_0),a
        ld (lane_mask_1),a
        ld (lane_mask_2),a
        ld (lane_mask_3),a
        ld (lane_visible_0),a
        ld (lane_visible_1),a
        ld (lane_visible_2),a
        ld (lane_visible_3),a
        ld (lane_frac_0),a
        ld (lane_frac_1),a
        ld (lane_frac_2),a
        ld (lane_frac_3),a
        ld (diver_state_0+1),a
        ld (diver_state_0+3),a
        ld (diver_state_1+1),a
        ld (diver_state_1+3),a
        ld (diver_state_2+1),a
        ld (diver_state_2+3),a
        ld (diver_state_3+1),a
        ld (diver_state_3+3),a
        ld (diver_fast_0),a
        ld (diver_fast_1),a
        ld (diver_fast_2),a
        ld (diver_fast_3),a
        ld (patrol_source_x),a
        ld (patrol_visible),a
        inc a
        ld (lane_reset_0),a
        ld (lane_reset_1),a
        ld (lane_reset_2),a
        ld (lane_reset_3),a
        ret

; A completed match always returns to player selection.  Latching the held
; trigger prevents the same press from immediately starting the default mode.
ReadGameOverRestart:
        xor a
        call GTTRIG
        or a
        ret z
        call InitAudio
        call InitTitle
        ld a,1
        ld (title_trigger_latch),a
        ret

; Keep the impact visible instead of teleporting immediately to the surface.
BeginPlayerDeath:
        ld a,(death_timer)
        or a
        ret nz
        ld a,23
        ld (death_timer),a
        xor a
        ld (torpedo_active),a
        ld (sfx_torpedo_counter),a
        ld (sfx_pickup_counter),a
        ld (sfx_shark_hit_counter),a
        ld (sfx_sub_hit_counter),a
        ld (collision_confirm),a
        ld (collision_seen),a
        ld (patrol_source_x),a
        ld (patrol_visible),a
        ld (hud_diver_blink_active),a
        ret

UpdateDeathSequence:
        ld a,(frame_counter)
        and 3
        ret nz                     ; source timer advances at 15 Hz, not 60 Hz
        ld a,(death_timer)
        dec a
        ld (death_timer),a
        ret nz
        jp ResetPlayerAfterDeath

; A=obstacle X. Test the actual opaque pixels of the current protagonist and
; shark/enemy-sub frame. The outline never enlarges the protagonist hitbox.
PlayerHitsX:
        cp 233                  ; invisible clipped sharks cannot collide
        ret nc
        ld (pixel_shark_x),a
        push ix
        push iy
        push bc                  ; C holds the lane base for later copies
        ld a,(player_y)
        ld b,a
        ld a,(collision_shark_y)
        ld c,a
        cp b
        jr nc,.shark_below
        ld d,b
        jr .have_start
.shark_below:
        ld d,c
.have_start:
        ld a,d
        sub b
        ld (pixel_player_row),a
        cp 16
        jp nc,.miss
        ld a,d
        sub c
        ld (pixel_shark_row),a
        cp 16
        jp nc,.miss
        ld b,a
        ld a,16
        sub b
        ld c,a
        ld a,(pixel_player_row)
        ld b,a
        ld a,16
        sub b
        cp c
        jr c,.rows_ready
        ld a,c
.rows_ready:
        ld (pixel_rows),a
        or a
        jp z,.miss
        ld hl,SubRight0
        ld a,(player_facing)
        or a
        jr z,.player_base
        ld hl,SubLeft0
.player_base:
        ld a,(player_anim)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld a,(pixel_player_row)
        ld e,a
        add hl,de
        push hl
        pop ix
        ld a,(collision_obstacle_type)
        or a
        jr nz,.enemy_sub_pattern
        ld hl,SharkRight0
        ld a,(collision_shark_dir)
        or a
        jr z,.shark_base
        ld hl,SharkLeft0
.shark_base:
        ld a,(frame_counter)
        and 8
        jr z,.shark_frame
        ld de,32
        add hl,de
.shark_frame:
        jr .obstacle_frame
.enemy_sub_pattern:
        ld hl,EnemySubRight0
        ld a,(collision_shark_dir)
        or a
        jr z,.enemy_sub_base
        ld hl,EnemySubLeft0
.enemy_sub_base:
        ld a,(player_anim)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        add hl,de
.obstacle_frame:
        ld a,(pixel_shark_row)
        ld e,a
        ld d,0
        add hl,de
        push hl
        pop iy
.row_loop:
        ld a,(iy+0)
        ld (pixel_shark_bits),a
        ld a,(pixel_shark_x)
        ld (pixel_global_x),a
        ld a,8
        ld (pixel_bit_count),a
.bit_loop:
        ld a,(pixel_shark_bits)
        add a,a
        ld (pixel_shark_bits),a
        jr nc,.next_bit
        ld a,(pixel_global_x)
        ld b,a
        ld a,(player_x)
        ld c,a
        ld a,b
        sub c
        jr c,.next_bit
        cp 16
        jr nc,.next_bit
        ld (pixel_local_x),a
        ld c,$80
        and 7
        jr z,.mask_ready
        ld b,a
.shift_mask:
        srl c
        djnz .shift_mask
.mask_ready:
        ld a,(pixel_local_x)
        cp 8
        ld a,(ix+0)
        jr c,.test_pixel
        ld a,(ix+16)
.test_pixel:
        and c
        jr nz,.hit
.next_bit:
        ld a,(pixel_global_x)
        inc a
        ld (pixel_global_x),a
        ld a,(pixel_bit_count)
        dec a
        ld (pixel_bit_count),a
        jr nz,.bit_loop
        inc ix
        inc iy
        ld a,(pixel_rows)
        dec a
        ld (pixel_rows),a
        jr nz,.row_loop
.miss:
        pop bc
        pop iy
        pop ix
        or a
        ret
.hit:
        pop bc
        pop iy
        pop ix
        scf
        ret

UpdateSprites:
        call WritePlayerSprite
        call WriteTorpedoSprite
        call WritePatrolSubSprite
        call WriteFourDiverSprites
        call UpdateHudDiverBlink
        call WriteHudDiverSprites
        call WriteEnemyTorpedoSprites
        ; All three green-lane copies must come from lane 0's own cache.
        ; V22 accidentally read lane_x_0, lane_x_1 and lane_x_2 as if they
        ; were three contiguous copies, mixing independent formations.
        ld hl,shark_x_cache_0
        ld a,(lane_dir_0)
        ld (draw_lane_dir),a
        ld a,(lane_type_0)
        ld (draw_lane_type),a
        ld a,(lane_visible_0)
        ld (draw_lane_mask),a
        ld iy,SAT_SHADOW+(SPR_LANE0*4)
        ld a,(lane_type_0)
        or a
        ld a,LANE0_Y
        jr nz,.lane0_y_ready
        ld a,(shark_float)
        add a,LANE0_Y
.lane0_y_ready:
        ld b,a
        call WriteLaneSprites
        ld hl,shark_x_cache_1
        ld a,(lane_dir_1)
        ld (draw_lane_dir),a
        ld a,(lane_type_1)
        ld (draw_lane_type),a
        ld a,(lane_visible_1)
        ld (draw_lane_mask),a
        ld iy,SAT_SHADOW+(SPR_LANE1*4)
        ld a,(lane_type_1)
        or a
        ld a,LANE1_Y
        jr nz,.lane1_y_ready
        ld a,(shark_float)
        add a,LANE1_Y
.lane1_y_ready:
        ld b,a
        call WriteLaneSprites
        ld hl,shark_x_cache_2
        ld a,(lane_dir_2)
        ld (draw_lane_dir),a
        ld a,(lane_type_2)
        ld (draw_lane_type),a
        ld a,(lane_visible_2)
        ld (draw_lane_mask),a
        ld iy,SAT_SHADOW+(SPR_LANE2*4)
        ld a,(lane_type_2)
        or a
        ld a,LANE2_Y
        jr nz,.lane2_y_ready
        ld a,(shark_float)
        add a,LANE2_Y
.lane2_y_ready:
        ld b,a
        call WriteLaneSprites
        ld hl,shark_x_cache_3
        ld a,(lane_dir_3)
        ld (draw_lane_dir),a
        ld a,(lane_type_3)
        ld (draw_lane_type),a
        ld a,(lane_visible_3)
        ld (draw_lane_mask),a
        ld iy,SAT_SHADOW+(SPR_LANE3*4)
        ld a,(lane_type_3)
        or a
        ld a,LANE3_Y
        jr nz,.lane3_y_ready
        ld a,(shark_float)
        add a,LANE3_Y
.lane3_y_ready:
        ld b,a
        jp WriteLaneSprites

WritePlayerSprite:
        ld a,(game_over)
        or a
        jr z,.check_death
        ld hl,SAT_SHADOW
        ld (hl),SPRITE_HIDE_Y
        ld hl,SAT_SHADOW+(SPR_PLAYER*4)
        ld (hl),SPRITE_HIDE_Y
        ret
.check_death:
        ld a,(death_timer)
        or a
        jr z,.alive
        ld hl,SAT_SHADOW
        ld (hl),SPRITE_HIDE_Y
        ld hl,SAT_SHADOW+(SPR_PLAYER*4)
        ld a,(player_y)
        add a,PLAYER_SCREEN_Y_OFFSET-1
        ld (hl),a
        inc hl
        ld a,(player_x)
        add a,VIEWPORT_X
        ld (hl),a
        inc hl
        ld a,(death_timer)
        cp 16
        ld a,PAT_EXPLOSION_0
        jr nc,.death_pattern
        ld a,(death_timer)
        cp 8
        ld a,PAT_EXPLOSION_1
        jr nc,.death_pattern
        ld a,PAT_EXPLOSION_2
.death_pattern:
        ld (hl),a
        ret
.alive:
        ld hl,SAT_SHADOW
        ; Back layer: one-pixel navy silhouette surrounding the body.
        ld a,(player_y)
        add a,PLAYER_SCREEN_Y_OFFSET-1
        ld (hl),a
        inc hl
        ld a,(player_x)
        add a,VIEWPORT_X
        ld (hl),a
        inc hl
        ld a,(player_anim)
        add a,a
        add a,a
        ld b,a
        ld a,(player_facing)
        or a
        jr nz,.outline_left
        ld a,b
        add a,PAT_OUTLINE_R0
        jr .outline_pattern
.outline_left:
        ld a,b
        add a,PAT_OUTLINE_L0
.outline_pattern:
        ld (hl),a
        ; Front layer: 14-pixel yellow body, sharing the same position.
        ld hl,SAT_SHADOW+(SPR_PLAYER*4)
        ld a,(player_y)
        add a,PLAYER_SCREEN_Y_OFFSET-1
        ld (hl),a
        inc hl
        ld a,(player_x)
        add a,VIEWPORT_X
        ld (hl),a
        inc hl
        ld a,(player_anim)
        add a,a
        add a,a
        ld b,a
        ld a,(player_facing)
        or a
        ld a,b
        jr z,.fill_pattern
        add a,PAT_SUB_L0
.fill_pattern:
        ld (hl),a
        ret

WriteTorpedoSprite:
        ld hl,SAT_SHADOW+(SPR_TORPEDO*4)
        ld a,(torpedo_active)
        or a
        jr z,.hide
        ld a,(torpedo_y)
        add a,PLAYER_SCREEN_Y_OFFSET-1
        ld (hl),a
        inc hl
        ld a,(torpedo_x)
        add a,VIEWPORT_X
        ld (hl),a
        inc hl
        ld a,(torpedo_dir)
        or a
        ld a,PAT_TORPEDO_R
        jr z,.store
        ld a,PAT_TORPEDO_L
.store:
        ld (hl),a
        ret
.hide:
        ld (hl),SPRITE_HIDE_Y
        ret

WritePatrolSubSprite:
        ld hl,SAT_SHADOW+(SPR_PATROL_SUB*4)
        ld a,(game_over)
        or a
        jr nz,.hide
        ld a,(death_timer)
        or a
        jr nz,.hide
        ld a,(patrol_visible)
        or a
        jr z,.hide
        ld (hl),PATROL_SUB_LOGICAL_Y+PLAYER_SCREEN_Y_OFFSET-1
        inc hl
        ld a,(patrol_screen_x)
        add a,VIEWPORT_X
        ld (hl),a
        inc hl
        ld a,(player_anim)
        add a,a
        add a,a
        add a,PAT_ENEMY_SUB_L0
        ld (hl),a
        inc hl
        ld (hl),0
        ret
.hide:
        ld (hl),SPRITE_HIDE_Y
        ret

WriteFourDiverSprites:
        ld ix,diver_state_0
        ld iy,SAT_SHADOW+(SPR_DIVER0*4)
        ld a,(diver_fast_0)
        ld (draw_diver_fast),a
        ld a,LANE0_Y+DIVER_Y_OFFSET
        call WriteOneDiverSprite
        ld ix,diver_state_1
        ld iy,SAT_SHADOW+(SPR_DIVER1*4)
        ld a,(diver_fast_1)
        ld (draw_diver_fast),a
        ld a,LANE1_Y+DIVER_Y_OFFSET
        call WriteOneDiverSprite
        ld ix,diver_state_2
        ld iy,SAT_SHADOW+(SPR_DIVER2*4)
        ld a,(diver_fast_2)
        ld (draw_diver_fast),a
        ld a,LANE2_Y+DIVER_Y_OFFSET
        call WriteOneDiverSprite
        ld ix,diver_state_3
        ld iy,SAT_SHADOW+(SPR_DIVER3*4)
        ld a,(diver_fast_3)
        ld (draw_diver_fast),a
        ld a,LANE3_Y+DIVER_Y_OFFSET
        jp WriteOneDiverSprite

WriteOneDiverSprite:
        ld b,a
        ld a,(ix+0)
        cp 1
        jr nz,.hide
        ; Keep the 8-pixel swimmer inside the 240-pixel logical viewport. Its
        ; source position still begins at XMAX, but the black MSX side margin
        ; must never reveal pixels that the Atari playfield would have clipped.
        ld a,(ix+1)
        cp 233
        jr nc,.hide
        ld a,b
        dec a
        ld (iy+0),a
        ld a,(ix+1)
        add a,VIEWPORT_X
        ld (iy+1),a
        ld a,(ix+2)
        or a
        ; SeaQuestJs draws the base rows normally for rightward movement.
        ld a,PAT_DIVER_R0
        jr z,.direction_ready
        ld a,PAT_DIVER_L0
.direction_ready:
        ld c,a
        ld a,(frame_counter)
        ld b,a
        ld a,(draw_diver_fast)
        or a
        ld a,b
        jr nz,.fast_animation
        srl a
.fast_animation:
        srl a
        srl a
.modulo_three:
        cp 3
        jr c,.frame_ready
        sub 3
        jr .modulo_three
.frame_ready:
        add a,a
        add a,a
        add a,c
.store:
        ld (iy+2),a
        ld (iy+3),0
        ret
.hide:
        ld (iy+0),SPRITE_HIDE_Y
        ret

; Six rescued swimmers blink between their normal near-black outline and the
; HUD's own gray from the sixth pickup until a safe surface arrival. A death
; immediately restores the normal color even though the lost swimmer is only
; deducted after the destruction animation. Color VRAM is touched only when
; the 16-frame phase changes.
UpdateHudDiverBlink:
        ld b,PAL_OUTLINE
        ld a,(retrieved_divers)
        cp 6
        jr nz,.apply
        ld a,(hud_diver_blink_active)
        or a
        jr z,.apply
        ld a,(reward_state)
        or a
        jr nz,.apply
        ld a,(death_timer)
        or a
        jr nz,.apply
        ld a,(game_over)
        or a
        jr nz,.apply
        ld a,(frame_counter)
        and $10
        jr z,.apply
        ld b,PAL_DARK_GRAY
.apply:
        ld a,(hud_diver_blink_color)
        cp b
        ret z
        ld a,b
        ld (hud_diver_blink_color),a
        ld hl,SPRITE_COLOR_TABLE+(SPR_HUD_DIVER0*16)
        ld bc,6*16
        jp FILVRM

WriteHudDiverSprites:
        ld iy,SAT_SHADOW+(SPR_HUD_DIVER0*4)
        ld a,(retrieved_divers)
        ld (hud_diver_count),a
        ld a,12
        ld (hud_diver_x),a
        ld b,6
.slot:
        ld a,(hud_diver_count)
        or a
        jr z,.hidden
        dec a
        ld (hud_diver_count),a
        ld (iy+0),HUD_DIVER_Y-1
        ld a,(hud_diver_x)
        ld (iy+1),a
        ld (iy+2),PAT_HUD_DIVER
        ld (iy+3),0
        jr .next
.hidden:
        ld (iy+0),SPRITE_HIDE_Y
.next:
        ld a,(hud_diver_x)
        add a,14
        ld (hud_diver_x),a
        ld de,4
        add iy,de
        djnz .slot
        ret

WriteEnemyTorpedoSprites:
        ld ix,diver_state_0
        ld iy,SAT_SHADOW+(SPR_ENEMY_TORPEDO0*4)
        ld b,LANE0_Y+ENEMY_TORPEDO_Y_OFFSET
        ld a,(lane_type_0)
        call WriteOneEnemyTorpedoSprite
        ld ix,diver_state_1
        ld iy,SAT_SHADOW+(SPR_ENEMY_TORPEDO1*4)
        ld b,LANE1_Y+ENEMY_TORPEDO_Y_OFFSET
        ld a,(lane_type_1)
        call WriteOneEnemyTorpedoSprite
        ld ix,diver_state_2
        ld iy,SAT_SHADOW+(SPR_ENEMY_TORPEDO2*4)
        ld b,LANE2_Y+ENEMY_TORPEDO_Y_OFFSET
        ld a,(lane_type_2)
        call WriteOneEnemyTorpedoSprite
        ld ix,diver_state_3
        ld iy,SAT_SHADOW+(SPR_ENEMY_TORPEDO3*4)
        ld b,LANE3_Y+ENEMY_TORPEDO_Y_OFFSET
        ld a,(lane_type_3)
        jp WriteOneEnemyTorpedoSprite

; A=lane type, B=screen top Y, IX=shared state, IY=SAT entry.
WriteOneEnemyTorpedoSprite:
        or a
        jr z,.hide
        ld a,(ix+1)
        or a
        jr z,.hide
        ld a,b
        dec a
        ld (iy+0),a
        ld a,(ix+1)
        add a,VIEWPORT_X
        ld (iy+1),a
        ld a,(ix+2)
        or a
        ld a,PAT_ENEMY_TORPEDO_R
        jr z,.pattern_ready
        ld a,PAT_ENEMY_TORPEDO_L
.pattern_ready:
        ld (iy+2),a
        ld (iy+3),0
        ret
.hide:
        ld (iy+0),SPRITE_HIDE_Y
        ret

; HL points to base X, IY to three SAT entries, B is screen Y.
WriteLaneSprites:
        ld a,1
        ld (draw_lane_bit),a
        call WriteLaneCopy
        ld a,2
        ld (draw_lane_bit),a
        call WriteLaneCopy
        ld a,4
        ld (draw_lane_bit),a
        jp WriteLaneCopy

WriteLaneCopy:
        ld a,(draw_lane_mask)
        ld d,a
        ld a,(draw_lane_bit)
        and d
        jr nz,.visible
        ld (iy+0),SPRITE_HIDE_Y
        inc hl
        ld de,4
        add iy,de
        ret
.visible:
        ld a,b
        dec a
        ld (iy+0),a
        ld a,(hl)
        add a,VIEWPORT_X
        ld (iy+1),a
        ld a,(draw_lane_type)
        or a
        jr nz,.enemy_sub_pattern
        ld a,(frame_counter)
        and 8
        ld a,(draw_lane_dir)
        or a
        ld a,PAT_SHARK_R0
        jr z,.direction_ready
        ld a,PAT_SHARK_L0
.direction_ready:
        ld d,a
        ld a,(frame_counter)
        and 8
        ld a,d
        jr z,.pattern_ready
        add a,4
.pattern_ready:
        ld (iy+2),a
        ld (iy+3),0
        inc hl
        ld de,4
        add iy,de
        ret
.enemy_sub_pattern:
        ld a,(player_anim)
        add a,a
        add a,a
        ld d,a
        ld a,(draw_lane_dir)
        or a
        ld a,PAT_ENEMY_SUB_R0
        jr z,.enemy_sub_direction_ready
        ld a,PAT_ENEMY_SUB_L0
.enemy_sub_direction_ready:
        add a,d
        jr .pattern_ready

UploadSprites:
        ld hl,SAT_SHADOW
        ld de,SPRITE_ATTR_TABLE
        ld bc,SPRITE_ATTR_BYTES
        jp LDIRVM

; Visible footer credit. The bitmap below is the 5x7 rendering of this exact
; string in palette color 12 over the black footer.
FooterSignatureText:
        db "(c) Activision 1983 / @filesguy 2026.",0
FooterSignatureRow0:
        db $00,$CC,$00,$00,$00,$00,$0C,$C0,$00,$00,$00,$00,$0C,$CC,$00,$00,$00,$00,$00,$C0,$00,$00,$C0,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$00,$0C,$CC,$00,$0C,$CC,$00,$CC,$CC,$00,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$0C,$CC,$00,$00,$CC,$00,$00,$C0,$00,$0C,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC,$00,$0C,$CC,$00,$0C,$CC,$00,$00,$CC,$00,$00,$00,$00
FooterSignatureRow1:
        db $0C,$00,$00,$0C,$CC,$00,$00,$0C,$00,$00,$00,$00,$C0,$00,$C0,$0C,$CC,$00,$00,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC,$C0,$00,$00,$00,$0C,$CC,$00,$C0,$CC,$00,$00,$00,$00,$0C,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$C0,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$C0,$00,$C0,$0C,$00,$C0,$00,$00,$00,$00,$C0,$00,$0C,$CC,$00,$0C,$CC,$C0,$0C,$CC,$C0,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$C0,$00,$C0,$C0,$00,$C0,$C0,$00,$C0,$0C,$00,$00,$00,$00,$00
FooterSignatureRow2:
        db $C0,$00,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$00,$C0,$00,$C0,$C0,$00,$00,$CC,$CC,$C0,$0C,$C0,$00,$C0,$00,$C0,$0C,$C0,$00,$C0,$00,$00,$0C,$C0,$00,$C0,$00,$C0,$CC,$00,$C0,$00,$00,$00,$00,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$C0,$CC,$C0,$0C,$00,$00,$0C,$C0,$00,$00,$C0,$00,$C0,$00,$C0,$C0,$00,$00,$C0,$00,$C0,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$00,$00,$C0,$C0,$0C,$C0,$00,$00,$C0,$C0,$00,$00,$00,$00,$00
FooterSignatureRow3:
        db $C0,$00,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$00,$CC,$CC,$C0,$C0,$00,$00,$00,$C0,$00,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$0C,$CC,$00,$00,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$00,$C0,$00,$0C,$CC,$C0,$0C,$CC,$00,$0C,$CC,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$00,$C0,$C0,$C0,$CC,$C0,$00,$00,$C0,$00,$00,$C0,$00,$CC,$CC,$C0,$0C,$CC,$00,$C0,$00,$C0,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$00,$0C,$00,$C0,$C0,$C0,$00,$0C,$00,$CC,$CC,$00,$00,$00,$00
FooterSignatureRow4:
        db $C0,$00,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$00,$C0,$00,$C0,$C0,$00,$00,$00,$C0,$00,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$00,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$00,$C0,$C0,$00,$C0,$00,$00,$C0,$00,$00,$00,$C0,$00,$00,$00,$00,$00,$C0,$CC,$C0,$0C,$00,$00,$00,$C0,$00,$00,$C0,$00,$C0,$00,$00,$00,$00,$C0,$0C,$CC,$C0,$C0,$00,$C0,$0C,$CC,$C0,$00,$00,$00,$00,$C0,$00,$CC,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$00,$00,$00
FooterSignatureRow5:
        db $0C,$00,$00,$C0,$00,$C0,$00,$0C,$00,$00,$00,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$0C,$0C,$00,$00,$C0,$00,$00,$00,$C0,$00,$C0,$00,$C0,$00,$C0,$C0,$00,$C0,$00,$00,$00,$00,$C0,$00,$00,$0C,$00,$C0,$00,$C0,$00,$00,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$C0,$00,$00,$0C,$00,$00,$00,$C0,$00,$00,$C0,$00,$C0,$00,$C0,$00,$00,$C0,$00,$00,$C0,$C0,$0C,$C0,$00,$00,$C0,$00,$00,$00,$0C,$00,$00,$C0,$00,$C0,$0C,$00,$00,$C0,$00,$C0,$0C,$C0,$00
FooterSignatureRow6:
        db $00,$CC,$00,$0C,$CC,$00,$0C,$C0,$00,$00,$00,$00,$C0,$00,$C0,$0C,$CC,$00,$00,$0C,$00,$0C,$CC,$00,$00,$C0,$00,$0C,$CC,$00,$CC,$CC,$00,$0C,$CC,$00,$0C,$CC,$00,$C0,$00,$C0,$00,$00,$00,$0C,$CC,$00,$CC,$C0,$00,$0C,$CC,$00,$CC,$CC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC,$00,$0C,$00,$00,$0C,$CC,$00,$0C,$CC,$00,$0C,$CC,$00,$CC,$CC,$00,$0C,$CC,$00,$0C,$C0,$C0,$0C,$CC,$00,$00,$00,$00,$CC,$CC,$C0,$0C,$CC,$00,$CC,$CC,$C0,$0C,$CC,$00,$0C,$C0,$00

; InitObstaclePatternIndexes normalized into the logical survivor masks used by
; the independent MSX render copies (left-side 4/6 become logical 1/3).
; Rounded values of (AUDF+1) * 171/8 for AUDF 0..31.
TiaDiv6TonePeriods:
        dw 21,43,64,86,107,128,150,171
        dw 192,214,235,257,278,299,321,342
        dw 363,385,406,428,449,470,492,513
        dw 534,556,577,599,620,641,663,684

; Rounded values of (AUDF+1) * 57/16 for AUDF 0..31.
TiaPoly9GatePeriods:
        dw 4,7,11,14,18,21,25,29
        dw 32,36,39,43,46,50,53,57
        dw 61,64,68,71,75,78,82,86
        dw 89,93,96,100,103,107,110,114

; Perceptual TIA AUDV -> AY fixed-volume conversion for the death fade.
; Index is Cartwright's linear source level 0..14. Values also compensate the
; lower average energy of the MSX tone/noise gate used to emulate POLY9.
DeathAyVolumeMap:
        db 0,7,9,10,11,12,12,13,13,14,14,15,15,15,15

FormationMasks:
        db 1,1,3,3,5,5,7,7

LaneFirstSpriteTable:
        db SPR_LANE0,SPR_LANE1,SPR_LANE2,SPR_LANE3

LaneSharkColorTable:
        db PAL_GREEN,PAL_BROWN,PAL_PURPLE,PAL_RED

; JS makes the source's floating graphic offset explicit as Y movement.
; Four frames per step, one 64-frame triangular cycle.
SharkFloatTable:
        db -4,-3,-2,-1,0,1,2,3,4,3,2,1,0,-1,-2,-3

PaletteData:
        ; byte 1 = 0RRR0BBB, byte 2 = 00000GGG
        db $00,$00             ; 0 black
        db $27,$03             ; 1 medium ultramarine sky
        db $25,$02             ; 2 unused dark water shade
        db $61,$02             ; 3 brick-red horizon (6,2,1)
        db $33,$03             ; 4 dark gray/floor
        db $77,$07             ; 5 white
        db $71,$06             ; 6 yellow
        db $17,$07             ; 7 cyan
        db $12,$06             ; 8 green
        db $51,$03             ; 9 brown
        db $56,$02             ; 10 purple
        db $71,$01             ; 11 red
        db $27,$00             ; 12 reference cobalt sea (2,0,7)
        db $33,$03             ; 13 dark gray
        db $55,$05             ; 14 patrol gray, TIA BLACK+9 equivalent
        db $01,$00             ; 15 near-black navy sprite outline

SurfaceWaveRow0:
        rept 30
        db $2E,$22,$E2,$22
        endr
SurfaceWaveRow1:
        rept 30
        db $22,$2E,$22,$E2
        endr
ReefRow0:
        rept 30
        db $CC,$C8,$CC,$8C
        endr
ReefRow1:
        rept 30
        db $C8,$88,$8C,$88
        endr
ReefRow2:
        rept 30
        db $88,$89,$88,$98
        endr
ReefRow3:
        rept 30
        db $89,$88,$98,$88
        endr

WaveColorPhases:
        db $AA,$AA,$11,$CC,$CC,$CC,$CC,$CC,$CC,$CC
        db $AA,$AA,$CC,$11,$CC,$CC,$CC,$CC,$CC,$CC
        db $AA,$AA,$CC,$CC,$11,$CC,$CC,$CC,$CC,$CC
        db $AA,$AA,$CC,$CC,$CC,$11,$CC,$CC,$CC,$CC

ReserveSubIconRows:
        db $11,$11,$16,$11,$11
        db $11,$11,$66,$11,$11
        db $61,$66,$66,$66,$11
        db $66,$66,$66,$66,$11
        db $16,$66,$66,$16,$11
        db $66,$66,$66,$61,$11

HudScoreRows:
        db $66,$61,$66,$61,$66,$61,$66,$61,$66,$61,$66,$61
        db $61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61
        db $61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61
        db $61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61,$61
        db $66,$61,$66,$61,$66,$61,$66,$61,$66,$61,$66,$61

HudOxygenRows:
        db $00,$0D,$0D,$0D,$0D,$0D,$00,$0D,$00,$0D,$0D,$0D
        db $0D,$0D,$0D,$0D,$0D,$0D,$0D,$DD,$0D,$DD,$00,$0D
        db $0D,$0D,$D0,$DD,$D0,$DD,$0D,$0D,$00,$DD,$00,$0D
        db $0D,$0D,$0D,$0D,$D0,$DD,$0D,$0D,$0D,$DD,$00,$0D
        db $00,$0D,$0D,$0D,$D0,$DD,$00,$0D,$00,$0D,$0D,$0D

; 8x9 rescued-diver icon: black figure over the gray HUD.
HudDiverRows:
        db $0D,$DD,$DD,$DD
        db $D0,$DD,$DD,$DD
        db $DD,$0D,$DD,$DD
        db $00,$00,$DD,$DD
        db $DD,$D0,$0D,$DD
        db $DD,$DD,$00,$00
        db $DD,$DD,$00,$DD
        db $DD,$DD,$DD,$D0
        db $DD,$DD,$DD,$D0

        include "assets.asm"

; Compact title-only data follows the gameplay assets in page 1.  The cartridge
; still reserves a second 16 KiB page for future work, but V38 does not depend on that
; page being selected by the BIOS during the cartridge initialization callback.

TitleLogoFont:
        ; S
        db %01110,%10000,%10000,%01110,%00001,%00001,%11110
        ; E
        db %11111,%10000,%10000,%11110,%10000,%10000,%11111
        ; A
        db %01110,%10001,%10001,%11111,%10001,%10001,%10001
        ; Q
        db %01110,%10001,%10001,%10001,%10101,%10010,%01101
        ; U
        db %10001,%10001,%10001,%10001,%10001,%10001,%01110
        ; E
        db %11111,%10000,%10000,%11110,%10000,%10000,%11111
        ; S
        db %01110,%10000,%10000,%01110,%00001,%00001,%11110
        ; T
        db %11111,%00100,%00100,%00100,%00100,%00100,%00100

TitleStartText:
        db "FIRE TO START",0
TitleOnePlayerText:
        db "1 PLAYER",0
TitleTwoPlayerText:
        db "2 PLAYERS",0

; 19-character 5x7 bitmap in the active player's color over PAL_SKY.  Copying
; seven 57-byte rows is deterministic and avoids BIOS font work during play.
SubClubColor6Bitmap:
        db $61,$11,$61,$66,$66,$61,$61,$11,$11,$16,$66,$61,$16,$66,$11,$61,$11,$61,$66,$66,$61,$11,$11,$11,$66,$66,$61,$16,$66,$11,$11,$11,$11,$16,$66,$61,$61,$11,$61,$66,$66,$11,$11,$11,$11,$16,$66,$61,$61,$11,$11,$61,$11,$61,$66,$66,$11
        db $61,$11,$61,$61,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$66,$16,$61,$61,$11,$11,$11,$11,$11,$11,$61,$11,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61
        db $61,$11,$61,$61,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$61,$61,$61,$11,$11,$11,$11,$11,$11,$61,$11,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61
        db $61,$61,$61,$66,$66,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$61,$61,$66,$66,$11,$11,$11,$11,$11,$61,$11,$61,$11,$61,$11,$11,$11,$16,$66,$11,$61,$11,$61,$66,$66,$11,$11,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$66,$66,$11
        db $61,$61,$61,$61,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61,$61,$11,$11,$11,$11,$11,$11,$61,$11,$61,$11,$61,$11,$11,$11,$11,$11,$61,$61,$11,$61,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61
        db $61,$61,$61,$61,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61,$61,$11,$11,$11,$11,$11,$11,$61,$11,$61,$11,$61,$11,$11,$11,$11,$11,$61,$61,$11,$61,$61,$11,$61,$11,$11,$11,$61,$11,$11,$61,$11,$11,$61,$11,$61,$61,$11,$61
        db $16,$16,$11,$66,$66,$61,$66,$66,$61,$16,$66,$61,$16,$66,$11,$61,$11,$61,$66,$66,$61,$11,$11,$11,$11,$61,$11,$16,$66,$11,$11,$11,$11,$66,$66,$11,$16,$66,$11,$66,$66,$11,$11,$11,$11,$16,$66,$61,$66,$66,$61,$16,$66,$11,$66,$66,$11
SubClubColor7Bitmap:
        db $71,$11,$71,$77,$77,$71,$71,$11,$11,$17,$77,$71,$17,$77,$11,$71,$11,$71,$77,$77,$71,$11,$11,$11,$77,$77,$71,$17,$77,$11,$11,$11,$11,$17,$77,$71,$71,$11,$71,$77,$77,$11,$11,$11,$11,$17,$77,$71,$71,$11,$11,$71,$11,$71,$77,$77,$11
        db $71,$11,$71,$71,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$77,$17,$71,$71,$11,$11,$11,$11,$11,$11,$71,$11,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71
        db $71,$11,$71,$71,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$71,$71,$71,$11,$11,$11,$11,$11,$11,$71,$11,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71
        db $71,$71,$71,$77,$77,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$71,$71,$77,$77,$11,$11,$11,$11,$11,$71,$11,$71,$11,$71,$11,$11,$11,$17,$77,$11,$71,$11,$71,$77,$77,$11,$11,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$77,$77,$11
        db $71,$71,$71,$71,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71,$71,$11,$11,$11,$11,$11,$11,$71,$11,$71,$11,$71,$11,$11,$11,$11,$11,$71,$71,$11,$71,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71
        db $71,$71,$71,$71,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71,$71,$11,$11,$11,$11,$11,$11,$71,$11,$71,$11,$71,$11,$11,$11,$11,$11,$71,$71,$11,$71,$71,$11,$71,$11,$11,$11,$71,$11,$11,$71,$11,$11,$71,$11,$71,$71,$11,$71
        db $17,$17,$11,$77,$77,$71,$77,$77,$71,$17,$77,$71,$17,$77,$11,$71,$11,$71,$77,$77,$71,$11,$11,$11,$11,$71,$11,$17,$77,$11,$11,$11,$11,$77,$77,$11,$17,$77,$11,$77,$77,$11,$11,$11,$11,$17,$77,$71,$77,$77,$71,$17,$77,$11,$77,$77,$11

MsxMusicSignature:
        db "APRLOPLL"

TitleFadeY:
        db 0,18,36,54,72,90,108,126,144,162,180,198
TitleFadeRows:
        db 18,18,18,18,18,18,18,18,18,18,18,14

; Compact three-voice title cue adapted from the user-supplied YELLOW_FM.BAS:
; one-beat B/C pickup followed by its B-A-A-G refrain contour at 112 BPM.
; Each row is duration, lead low/high, harmony low/high, bass low/high.
TitleYellowFmEvents:
        db 24, $45,$19, $00,$00, $00,$00
        db  8, $AC,$1A, $00,$00, $00,$00
        db 32, $45,$19, $C1,$18, $02,$15
        db 32, $45,$19, $C1,$18, $02,$15
        db 32, $45,$19, $C1,$18, $02,$15
        db 24, $45,$19, $C1,$18, $02,$15
        db  8, $AC,$1A, $C1,$18, $02,$15
        db 24, $22,$19, $F4,$18, $C1,$16
        db  8, $22,$19, $F4,$18, $C1,$16
        db 24, $22,$19, $F4,$18, $C1,$16
        db  8, $22,$19, $F4,$18, $C1,$16
        db 64, $22,$19, $F4,$18, $C1,$16
        db 24, $22,$19, $F4,$18, $C1,$16
        db  8, $22,$19, $F4,$18, $C1,$16
        db 24, $22,$19, $F4,$18, $C1,$16
        db  8, $22,$19, $F4,$18, $C1,$16
        db 64, $22,$19, $F4,$18, $C1,$16
        db 24, $02,$19, $C1,$18, $02,$15
        db  8, $02,$19, $C1,$18, $02,$15
        db 24, $02,$19, $C1,$18, $02,$15
        db  8, $02,$19, $C1,$18, $02,$15
        db 64, $02,$19, $C1,$18, $02,$15
        db 0

; AY-3-8910 channel-C periods for the same sixteen notes at the MSX clock.
TitlePsgPeriods:
        dw 428,339,285,254
        dw 285,339,381,0
        dw 339,285,214,226
        dw 254,285,214,0

        ds $C000-$,$FF
