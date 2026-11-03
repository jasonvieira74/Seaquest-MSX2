; V1 sprite patterns.
; Atari source rows were stored bottom-up. These rows are top-down for MSX.
; 16x16 order: 16 left-half rows followed by 16 right-half rows.
; Original eight-pixel art occupies only the left half; it is not stretched.

SpritePatterns:

SubRight0:
        db $00,$00,$00,$00,$00,$00,$00,$67,$7F,$1F,$7F,$7F,$00,$00,$00,$00
        db $00,$00,$60,$E0,$E0,$E0,$E0,$FE,$FE,$E6,$FE,$F8,$00,$00,$00,$00
SubRight1:
        db $00,$00,$00,$00,$00,$00,$00,$67,$1F,$7F,$7F,$1F,$60,$00,$00,$00
        db $00,$00,$60,$E0,$E0,$E0,$E0,$FE,$FE,$E6,$FE,$F8,$00,$00,$00,$00
SubRight2:
        db $00,$00,$00,$00,$00,$00,$00,$07,$7F,$7F,$1F,$7F,$60,$00,$00,$00
        db $00,$00,$60,$E0,$E0,$E0,$E0,$FE,$FE,$E6,$FE,$F8,$00,$00,$00,$00

; Horizontal bit reversals of the right-facing frames.
SubLeft0:
        db $00,$00,$06,$07,$07,$07,$07,$7F,$7F,$67,$7F,$1F,$00,$00,$00,$00
        db $00,$00,$00,$00,$00,$00,$00,$E6,$FE,$F8,$FE,$FE,$00,$00,$00,$00
SubLeft1:
        db $00,$00,$06,$07,$07,$07,$07,$7F,$7F,$67,$7F,$1F,$00,$00,$00,$00
        db $00,$00,$00,$00,$00,$00,$00,$E6,$F8,$FE,$FE,$F8,$06,$00,$00,$00
SubLeft2:
        db $00,$00,$06,$07,$07,$07,$07,$7F,$7F,$67,$7F,$1F,$00,$00,$00,$00
        db $00,$00,$00,$00,$00,$00,$00,$E0,$FE,$FE,$F8,$FE,$06,$00,$00,$00

TorpedoRight:
        db $00,$00,$00,$00,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
TorpedoLeft:
        db $00,$00,$00,$00,$00,$00,$0F,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0

SharkRight0:
        db $08,$0C,$DF,$7F,$7F,$D8,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
SharkRight1:
        db $08,$8C,$DF,$7F,$7E,$DB,$91,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
SharkLeft0:
        db $10,$30,$FB,$FE,$FE,$1B,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
SharkLeft1:
        db $10,$31,$FB,$FE,$7E,$DB,$89,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0

; The outline contains only the one-pixel ring, never the yellow body itself.
SubOutlineRight0:
        db $00,$00,$01,$01,$01,$01,$FF,$98,$80,$E0,$80,$80,$FF,$00,$00,$00
        db $00,$F0,$90,$10,$10,$10,$1F,$01,$01,$19,$01,$07,$FC,$00,$00,$00
SubOutlineRight1:
        db $00,$00,$01,$01,$01,$01,$FF,$98,$E0,$80,$80,$E0,$9F,$F0,$00,$00
        db $00,$F0,$90,$10,$10,$10,$1F,$01,$01,$19,$01,$07,$FC,$00,$00,$00
SubOutlineRight2:
        db $00,$00,$01,$01,$01,$01,$0F,$F8,$80,$80,$E0,$80,$9F,$F0,$00,$00
        db $00,$F0,$90,$10,$10,$10,$1F,$01,$01,$19,$01,$07,$FC,$00,$00,$00
SubOutlineLeft0:
        db $00,$0F,$09,$08,$08,$08,$F8,$80,$80,$98,$80,$E0,$3F,$00,$00,$00
        db $00,$00,$80,$80,$80,$80,$FF,$19,$01,$07,$01,$01,$FF,$00,$00,$00
SubOutlineLeft1:
        db $00,$0F,$09,$08,$08,$08,$F8,$80,$80,$98,$80,$E0,$3F,$00,$00,$00
        db $00,$00,$80,$80,$80,$80,$FF,$19,$07,$01,$01,$07,$F9,$0F,$00,$00
SubOutlineLeft2:
        db $00,$0F,$09,$08,$08,$08,$F8,$80,$80,$98,$80,$E0,$3F,$00,$00,$00
        db $00,$00,$80,$80,$80,$80,$F0,$1F,$01,$01,$07,$01,$F9,$0F,$00,$00

; Full 14-line animation in the exact top-to-bottom order used by SeaQuestJs.
; Its drawSprite() iterates line 0 toward increasing Y, so no vertical reversal
; is required. Left frames are pure horizontal bit reversals.
DiverRight0:
        db $20,$20,$00,$08,$08,$02,$02,$0C,$0F,$18,$F0,$20,$40,$80,$00,$00
        ds 16,0
DiverRight1:
        db $20,$00,$20,$10,$00,$02,$02,$0C,$0F,$18,$30,$60,$80,$00,$00,$00
        ds 16,0
DiverRight2:
        db $00,$20,$10,$00,$08,$02,$02,$0C,$0F,$18,$F0,$20,$40,$80,$00,$00
        ds 16,0
DiverLeft0:
        db $04,$04,$00,$10,$10,$40,$40,$30,$F0,$18,$0F,$04,$02,$01,$00,$00
        ds 16,0
DiverLeft1:
        db $04,$00,$04,$08,$00,$40,$40,$30,$F0,$18,$0C,$06,$01,$00,$00,$00
        ds 16,0
DiverLeft2:
        db $00,$04,$08,$00,$10,$40,$40,$30,$F0,$18,$0F,$04,$02,$01,$00,$00
        ds 16,0

HudDiver:
        db $00,$00,$02,$02,$0C,$0F,$18,$F0,$20,$40,$80,$00,$00,$00,$00,$00
        ds 16,0

Explosion0:
        db $00,$00,$00,$00,$00,$10,$28,$10,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
Explosion1:
        db $00,$00,$00,$44,$10,$00,$28,$00,$10,$44,$00,$00,$00,$00,$00,$00
        ds 16,0
Explosion2:
        db $00,$00,$82,$10,$00,$00,$54,$00,$00,$10,$82,$00,$00,$00,$00,$00
        ds 16,0

; Enemy lane submarines reuse Cartwright's original eight-pixel submarine art
; without the protagonist's MSX-only horizontal enlargement or outline. Atari
; rows are reversed here into the MSX top-to-bottom order.
EnemySubRight0:
        db $00,$00,$04,$0C,$0C,$0C,$0C,$BF,$FF,$7D,$FF,$FE,$00,$00,$00,$00
        ds 16,0
EnemySubRight1:
        db $00,$00,$04,$0C,$0C,$0C,$0C,$BF,$7F,$FD,$FF,$7E,$80,$00,$00,$00
        ds 16,0
EnemySubRight2:
        db $00,$00,$04,$0C,$0C,$0C,$0C,$3F,$FF,$FD,$7F,$FE,$80,$00,$00,$00
        ds 16,0

; Strict horizontal bit reversals for leftward movement.
EnemySubLeft0:
        db $00,$00,$20,$30,$30,$30,$30,$FD,$FF,$BE,$FF,$7F,$00,$00,$00,$00
        ds 16,0
EnemySubLeft1:
        db $00,$00,$20,$30,$30,$30,$30,$FD,$FE,$BF,$FF,$7E,$01,$00,$00,$00
        ds 16,0
EnemySubLeft2:
        db $00,$00,$20,$30,$30,$30,$30,$FC,$FF,$BF,$FE,$7F,$01,$00,$00,$00
        ds 16,0

; TIA BALL reconstruction. SeaQuestJs makes the four active scanlines explicit:
; a four-pixel pulse on row 0 and another on row 3. The left frame is a strict
; horizontal reflection, matching the enemy submarine's travel direction.
EnemyTorpedoRight:
        db $3C,$00,$00,$0F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
EnemyTorpedoLeft:
        db $3C,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0

SpritePatternsEnd:
