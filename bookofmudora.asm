;================================================================================
; Randomize Book of Mudora
;--------------------------------------------------------------------------------
LoadLibraryItemGFX:
	%GetPossiblyEncryptedPlayerID(LibraryItem_Player) : STA !MULTIWORLD_SPRITEITEM_PLAYER_ID
	%GetPossiblyEncryptedItem(LibraryItem, SpriteItemValues)
	STA $0E80, X ; Store item type
	JSL.l PrepDynamicTile
RTL
;--------------------------------------------------------------------------------
DrawLibraryItemGFX:
	PHA
    LDA $0E80, X ; Retrieve stored item type
	JSL.l DrawDynamicTile
	PLA
RTL
;--------------------------------------------------------------------------------
SetLibraryItem:
    PHA
	LDY $0E80, X ; Retrieve stored item type
	PLA
	JSL.l ItemSet_Library ; contains thing we wrote over
RTL
;--------------------------------------------------------------------------------

;0x0087 - Hera Room w/key
;================================================================================
; Randomize Bonk Keys
;--------------------------------------------------------------------------------
!REDRAW = "$7F5000"
!BONK_ITEM_ROOM = "$7F5400"
!BONK_ITEM_PLAYER_ROOM = "$7F5401"
!BONK_ITEM = "$7F5402"
!BONK_ITEM_PLAYER = "$7F5403"
;--------------------------------------------------------------------------------
LoadBonkItemGFX:
	LDA.b #$08 : STA $0F50, X ; thing we wrote over
LoadBonkItemGFX_inner:
	LDA.b #$00 : STA !REDRAW
	JSR LoadBonkItem_Player : STA !MULTIWORLD_SPRITEITEM_PLAYER_ID
	JSR LoadBonkItem
	JSL.l PrepDynamicTile
RTL
;--------------------------------------------------------------------------------
DrawBonkItemGFX: 
	PHA
	LDA !REDRAW : BEQ .skipInit ; skip init if already ready
	JSL.l LoadBonkItemGFX_inner
	BRA .done ; don't draw on the init frame
	
	.skipInit
	
    JSR LoadBonkItem
	JSL.l DrawDynamicTileNoShadow
	
	.done
	PLA
RTL
;--------------------------------------------------------------------------------
GiveBonkItem:
	JSR LoadBonkItem_Player : STA !MULTIWORLD_ITEM_PLAYER_ID
	JSR LoadBonkItem
	CMP #$24 : BNE .notKey
	.key
		PHY : LDY.b #$24 : JSL.l AddInventory : PLY ; do inventory processing for a small key
		LDA $7EF36F : INC A : STA $7EF36F
		LDA.b #$2F : JSL.l Sound_SetSfx3PanLong
		JSL CountBonkItem
RTL
	.notKey
		PHY : TAY : JSL.l Link_ReceiveItem : PLY
		JSL CountBonkItem
RTL
;--------------------------------------------------------------------------------
LoadBonkItem:
	LDA $A0 ; check room ID - only bonk keys in 2 rooms so we're just checking the lower byte
	CMP !BONK_ITEM_ROOM : BNE + : LDA !BONK_ITEM : BRA ++
	+ : STA !BONK_ITEM_ROOM
	CMP #115 : BNE + ; Desert Bonk Key
    	%GetPossiblyEncryptedItem(BonkKey_Desert, HeartPieceIndoorValues) : STA !BONK_ITEM
		BRA ++
	+ : CMP #140 : BNE + ; GTower Bonk Key
		%GetPossiblyEncryptedItem(BonkKey_GTower, HeartPieceIndoorValues) : STA !BONK_ITEM
		BRA ++
	+
		LDA.b #$24 : STA !BONK_ITEM ; default to small key
	++
RTS
;--------------------------------------------------------------------------------
LoadBonkItem_Player:
	LDA $A0 ; check room ID - only bonk keys in 2 rooms so we're just checking the lower byte
	CMP !BONK_ITEM_PLAYER_ROOM : BNE + : LDA !BONK_ITEM_PLAYER : BRA ++
	+ : STA !BONK_ITEM_PLAYER_ROOM
	CMP #115 : BNE + ; Desert Bonk Key
		%GetPossiblyEncryptedPlayerID(BonkKey_Desert_Player) : STA !BONK_ITEM_PLAYER
		BRA ++
	+ : CMP #140 : BNE + ; GTower Bonk Key
    	%GetPossiblyEncryptedPlayerID(BonkKey_GTower_Player) : STA !BONK_ITEM_PLAYER
		BRA ++
	+
		LDA.b #$00 : STA !BONK_ITEM_PLAYER
	++
RTS
