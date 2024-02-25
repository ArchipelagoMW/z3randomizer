;--------------------------------------------------------------------------------
; 291 - Moldorm Cave
; 286 - Northeast Dark Swamp Cave
;--------------------------------------------------------------------------------
!BIGRAM = "$7EC900";
;--------------------------------------------------------------------------------
!SPRITE_OAM = "$7EC025"
; A = Tile ID
macro UploadOAM(dest)
	PHA : PHP

	PHA
		REP #$20 ; set 16-bit accumulator
		LDA.w #$0000 : STA.l !SPRITE_OAM
		               STA.l !SPRITE_OAM+2
		LDA.w #$0200 : STA.l !SPRITE_OAM+6
		SEP #$20 ; set 8-bit accumulator
		LDA.b <dest> : STA.l !SPRITE_OAM+4

	LDA $01,s

		JSL.l GetSpritePalette
		STA !SPRITE_OAM+5 : STA !SPRITE_OAM+13
	PLA
	JSL.l IsNarrowSprite : BCS .narrow

	BRA .done

	.narrow
	REP #$20 ; set 16-bit accumulator
	LDA.w #$0000 : STA.l !SPRITE_OAM+7
	               STA.l !SPRITE_OAM+14
	LDA.w #$0800 : STA.l !SPRITE_OAM+9
	LDA.w #$3400 : STA.l !SPRITE_OAM+11

	.done
	PLP : PLA
endmacro

BigRAMStore:
	STA !BIGRAM, X : INX : INX : RTS
;--------------------------------------------------------------------------------
; $0A : Digit Offset
; $0C-$0D : Value to Display
; $0E-$0F : Base Coordinate
;--------------------------------------------------------------------------------
macro DrawDigit(value,offset)
	STZ $0A ; clear digit buffer
	LDA $0C ; load value
	--
	CMP.w <value> : !BLT ++
		!SUB.w <value>
		INC $0A
		BRA --
	++
	STA $0C ; save value
	CPY.b #$FF : BNE +
		LDY.b <offset>
		LDA $0E : !ADD.w .digit_offsets, Y : STA $0E
	+
	LDA $0E : JSR BigRAMStore
	LDA.w #56 : JSR BigRAMStore
	LDA $A0 : CMP.l #$109 : BNE + : LDA.w #$FFCA : STA !BIGRAM-2, X : + 
	LDY $0A : TYA : ASL : TAY : LDA.w .digit_properties, Y : JSR BigRAMStore
	LDA.w #$0000 : JSR BigRAMStore
	
	LDA $0E : !ADD.w #$0008 : STA $0E ; move offset 8px right
endmacro
;--------------------------------------------------------------------------------
!COLUMN_LOW = "$7F5022"
!COLUMN_HIGH = "$7F5023"
!SHOP_INVENTORY_PLAYER = "$7F5062"
!SHOP_INVENTORY = "$7F5052" ; $7F5056 - 5a - 5e
!SCRATCH_TEMP_X = "$7F506B"
DrawPrice:
	STX $07
	PHX : PHY : PHP
		LDY.b #$FF
		LDX #$00 ; clear bigram pointer

		REP #$20

		; set up shop shuffle star
		; i set it all up before then backtrack (dex #8) because i hate 16-bit 8-bit accumulator logic mixups
		LDA $0E : !ADD.w #$10 : JSR BigRAMStore ; change this to a set distance from center
		LDA.w #36 : JSR BigRAMStore
		LDA $A0 : CMP.l #$109 : BNE + : LDA.w #$FFAA : STA !BIGRAM-2, X : + 
		LDA.w #$0391 : JSR BigRAMStore ; Yellow Star
		LDA.w #$0000 : JSR BigRAMStore : STX $06

		SEP #$20 ; set 8-bit accumulator
		LDX $07 : LDA.l !SHOP_INVENTORY+3, X : CMP.b #$40 : !BGE +++ ; do not render on base items
			; LDA.b $07 : LSR #2 : TAX : LDA.l !SHOP_INVENTORY_PLAYER, X : BEQ ++ ; use a different icon if multiworld
			; LDX $06 : LDA.b #$09 : STA !BIGRAM-3, X : LDA.b #$92 : STA !BIGRAM-4, X : BRA ++++ : ++
			LDX $06 : BRA ++++
		+++ : LDX $06 : DEX #8
		++++
		REP #$20

		LDA $0D : AND.w #$80 : BNE ++ 
			BRL .normal_price
			++
			; AT price location $0C-0D
			; 0D item type (if highest bit is set 0x80, use 0x7F to determine type of price)
			; 0C special price value 1-255
			; Rupees = (normal price type)
			; Hearts = 0
			; Magic = 1
			; Bomb = 2
			; Arrows = 3
			; HeartContainer = 4
			; BombUpgrade = 5
			; ArrowUpgrade = 6
			; Keys = 7
			; Potion = 8
			; Item = 9
			LDA $0E : !SUB.W #$04 : JSR BigRAMStore
			LDA.w #56 : JSR BigRAMStore
			LDA $A0 : CMP.l #$109 : BNE + : LDA.w #$FFCA : STA !BIGRAM-2, X : + ; potion shop check
			LDA $0D : AND #$000F : ASL : PHX : TAX : PHX : LSR : TAX;; Store OAM X, ICON array X (with A), LSR then get Adjust, then PLX 
			LDA $0C : AND.w #$FF
			LDY .adjust_value, X : BEQ + ; Adjust "value" to less arbitrary number, (a 255 value of magic reduced to 32 pips) but should probably just use graphcis
				- : LSR : DEY : BNE -
			+ : STA $0C : PLX
			LDA.w .icon_graphics, X : PLX : JSR BigRAMStore
			; Compare current Icon_Graphics (didn't feel like reloading price) to determine further icon adjusting
			; We should be able to just write new graphics and patch them in instead, but I don't know how to do that with SNES
			CMP.w #$0563 : BNE +
				LDA.w #54
				JSR LongPriceIcon
				LDA.w #$0573 : JSR BigRAMStore
			+
			CMP.w #$0D63 : BNE +
				LDA.w #54
				JSR LongPriceIcon
				LDA.w #$0D73 : JSR BigRAMStore
			+
			CMP.w #$056B : BNE +
				LDA.w #53
				JSR LongPriceIcon
				LDA.w #$057B : JSR BigRAMStore
			+
			CMP.w #$0272 : BNE +
				PHX 
				LDA $0C : ASL : TAX : LDA .icon_graphics_bottle, X
				PLX : STA !BIGRAM-2, X
				LDA.w #$0000 : JSR BigRAMStore
				LDA $0E : !ADD.w #$8 : STA $0E ; move offset 8px right
				BRL .len0
			+
			.icon_done
			LDA.w #$0000 : JSR BigRAMStore
			LDA $0E : !ADD.w #$8 : STA $0E ; move offset 8px right
			BRL .len2

		.normal_price
		LDA $0C : CMP.w #1000 : !BLT + : BRL .len4 : +
				  CMP.w #100 : !BLT + : BRL .len3 : +
				  CMP.w #10 : !BLT + : BRL .len2 : +
				  CMP.w #1 : !BLT + : BRL .len1 : + JMP .len0

			.len4
				%DrawDigit(#1000,#6)
			
			.len3
				%DrawDigit(#100,#4)
			
			.len2
				%DrawDigit(#10,#2)
			
			.len1
			.len0	
				%DrawDigit(#1,#0)

		.okay				

		SEP #$20

		TXA : LSR #3 : STA $06 ; request 1-4 OAM slots
		ASL #2
			PHA
				LDA $22 : CMP !COLUMN_LOW : !BLT .off
						  CMP !COLUMN_HIGH : !BGE .off
				.on
				PLA : JSL.l OAM_AllocateFromRegionB : BRA + ; request 4-16 bytes
				.off
				PLA : JSL.l OAM_AllocateFromRegionA ; request 4-16 bytes
			+
		TXA : LSR #3
	PLP : PLY : PLX
RTS
;--------------------------------------------------------------------------------
.digit_properties
dw $0230, $0231, $0202, $0203, $0212, $0213, $0222, $0223, $0232, $0233
;--------------------------------------------------------------------------------
.digit_offsets
dw 4, 0, -4, -8
;--------------------------------------------------------------------------------
.icon_graphics
dw $0329, $0960, $8570, $0563, $0d29, $8d70, $0d63, $056b, $0272, $0991
;-------------------------------------------------------------------
.icon_graphics_bottle
dw $0372, $0972, $0572, $0b72, $0d72, $0d72
;--------------------------------------------------------------------------------
.adjust_value:
db $03, $03, $00, $00, $03, $00, $00, $00, $00, $00, $00, $00
;------
ResourceOffset: ; where is our special price (8-bit) in memory relative to memaddress (i forgot the address)
db $6D, $6E, $43, $77, $6C, $70, $71, $6F, $00

LongPriceIcon:
	; A == Y offset
	; Y == secondary Y offset (potentially)
	STA !BIGRAM-4, X ; TODO: use subtraction for potion shop offset
	LDA $A0 : CMP.l #$109 : BNE + : LDA.w #$FFC8 : STA !BIGRAM-4, X : + 
	LDA.w #$0000 : JSR BigRAMStore
	LDA $0E : !SUB.W #$04 : JSR BigRAMStore ; arrow Y POSITION
	LDA.w #58 : JSR BigRAMStore
	LDA $A0 : CMP.l #$109 : BNE + : LDA.w #$FFC8 : STA !BIGRAM-2, X : + 
	RTS

;--------------------------------------------------------------------------------
!TILE_UPLOAD_OFFSET_OVERRIDE = "$7F5042"
!FREE_TILE_BUFFER = "#$1180"
!SHOP_ENABLE_COUNT = "$7F504F"
!SHOP_ID = "$7F5050"
!SHOP_TYPE = "$7F5051"
;!SHOP_INVENTORY = "$7F5052" ; $7F5056 - 5a - 5e
;!SHOP_INVENTORY_PLAYER = "$7F5062"
!SHOP_INVENTORY_DISGUISE = "$7F5065" ; was going to remove this, but this lets more than one bee trap exist with its own icon.  that might be excessive, but seeing two items obviously reveals if there's one or more beetraps
!SHOP_STATE = "$7F5069"
!SHOP_CAPACITY = "$7F506A"
;!SCRATCH_TEMP_X = "$7F506B"
!SHOP_SRAM_INDEX = "$7F506C"
!SHOP_MERCHANT = "$7F506D"
!SHOP_DMA_TIMER = "$7F506E"
!SHOP_KEEP_REFILL = "$7F506F"

;--------------------------------------------------------------------------------
!NMI_AUX = "$7F5044"
;--------------------------------------------------------------------------------
SpritePrep_ShopKeeper:
	PHX : PHY : PHP
	
	REP #$30 ; set 16-bit accumulator & index registers
	LDX.w #$0000
	-
		LDA ShopTable+1, X : CMP $A0 : BNE +
		;LDA ShopTable+3, X : CMP $010E : BNE +
		LDA ShopTable+5, X : AND.w #$0040 : BNE ++
			LDA $7F5099 : AND #$00FF : CMP ShopTable+3, X : BNE +
		++
			SEP #$20 ; set 8-bit accumulator
			LDA ShopTable, X : STA !SHOP_ID
			LDA ShopTable+5, X : STA !SHOP_TYPE
			AND.b #$03 : ASL #2 : STA !SHOP_CAPACITY
			LDA ShopTable+6, X : STA !SHOP_MERCHANT
			LDA ShopTable+7, X : STA !SHOP_SRAM_INDEX
			BRA .success
		+
		LDA ShopTable, X : AND.w #$00FF : CMP.w #$00FF : BEQ .fail
		INX #8 ;; width of shop table
	BRA -
	
	.fail
	SEP #$20 ; set 8-bit accumulator
	LDA.b #$FF : STA !SHOP_TYPE ; $FF = error condition
	BRL .done
	
	.success
	SEP #$20 ; set 8-bit accumulator
	LDX.w #$0000
	LDY.w #$0000
	-
		TYA : CMP !SHOP_CAPACITY : !BLT ++ : BRL .stop : ++
		LDA.l ShopContentsTable+1, X : CMP.b #$FF : BNE ++ : BRL .stop : ++
		
		LDA.l ShopContentsTable, X : CMP !SHOP_ID : BEQ ++ : BRL .next : ++

		JSR SetupShopItem
		INY #4 ; width of shop inventory item
		
		.next
		INX #9 ; width of shop contents table
	BRL -
	.stop
	
	LDA #$01 : STA !NMI_AUX+2 : STA !NMI_AUX

	.done

	LDA.l !SHOP_TYPE : BIT.b #$20 : BEQ .notTakeAll ; Take-all
	.takeAll
		LDA.b #$00 : XBA : LDA !SHOP_SRAM_INDEX : TAX
		LDA.l !SHOP_PURCHASE_COUNTS, X
		BRA ++
	.notTakeAll
		LDA.b #$00
	++
	STA !SHOP_STATE

    ; If the item is $FF, make it not show (as if already taken)
	LDA !SHOP_INVENTORY : CMP.b #$FF : BNE +
		LDA !SHOP_STATE : ORA.l Shopkeeper_ItemMasks : STA !SHOP_STATE
	+
	LDA !SHOP_INVENTORY+4 : CMP.b #$FF : BNE +
		LDA !SHOP_STATE : ORA.l Shopkeeper_ItemMasks+1 : STA !SHOP_STATE
	+
	LDA !SHOP_INVENTORY+8 : CMP.b #$FF : BNE +
		LDA !SHOP_STATE : ORA.l Shopkeeper_ItemMasks+2 : STA !SHOP_STATE
	+

	PLP : PLY : PLX
	
	LDA.l !SHOP_TYPE : CMP.b #$FF : BNE +
		PLA : PLA : PLA
        INC $0BA0, X
        LDA $0E40, X
		JML.l ShopkeeperFinishInit
	+
RTL
SetupShopItem:
	LDA.l ShopContentsTable+1, X : PHX : TYX : STA.l !SHOP_INVENTORY, X : PLX
	LDA.l ShopContentsTable+2, X : PHX : TYX : STA.l !SHOP_INVENTORY+1, X : PLX
	LDA.l ShopContentsTable+3, X : PHX : TYX : STA.l !SHOP_INVENTORY+2, X : PLX
	LDA.l ShopContentsTable+8, X : PHX : PHA
	LDA #0 : XBA : TYA : LSR #2 : TAX ; This will convert the value back to the slot number (in 8-bit accumulator mode)
	PLA : STA.l !SHOP_INVENTORY_PLAYER, X : LDA #0 : STA.l !SHOP_INVENTORY_DISGUISE, X : PLX
	
	PHY
		PHX
			LDA.b #$00 : XBA : TYA : LSR #2 : !ADD !SHOP_SRAM_INDEX : TAX
			LDA !SHOP_PURCHASE_COUNTS, X : TYX : STA.l !SHOP_INVENTORY+3, X : TAY
		PLX
		
		LDA.l ShopContentsTable+4, X : BEQ +
		TYA : CMP.l ShopContentsTable+4, X : !BLT ++
			PLY
				LDA.l ShopContentsTable+5, X : PHX : TYX : STA.l !SHOP_INVENTORY, X : PLX
				LDA.l ShopContentsTable+6, X : PHX : TYX : STA.l !SHOP_INVENTORY+1, X : PLX
				LDA.l ShopContentsTable+7, X : PHX : TYX : STA.l !SHOP_INVENTORY+2, X : PLX
				LDA #$40 : PHX : TYX : STA.l !SHOP_INVENTORY+3, X : PLX
				PHX : LDA #0 : XBA : TYA : LSR #2 : TAX ; This will convert the value back to the slot number (in 8-bit accumulator mode)
				LDA #0 : STA.l !SHOP_INVENTORY_PLAYER, X : PLX
				BRA +++
			+ : PLY : LDA #$40 : PHX : TYX : STA.l !SHOP_INVENTORY+3, X : PLX : BRA +++
		++ : PLY
	+++

	PHX : PHY
		PHX : TYX : LDA.l !SHOP_INVENTORY, X : PLX
		CMP #$5A : BEQ ++
		CMP #$B0 : BNE + : ++
			PHX : LDA #0 : XBA : TYA : LSR #2 : TAX ; This will convert the value back to the slot number (in 8-bit accumulator mode)
			JSL GetRandomInt : AND #$3F : STA !BEE_TRAP_DISGUISE
			BNE ++ : LDA #$49 : ++ : CMP #$26 : BNE ++ : LDA #$6A : ++ ; if 0 (fighter's sword + shield), set to just sword, if filled container (bugged palette), switch to triforce piece
			STA.l !SHOP_INVENTORY_DISGUISE, X : PLX
		+ : TAY
		REP #$20 ; set 16-bit accumulator
		LDA 1,s : TAX : LDA.l .tile_offsets, X : TAX
		JSR LoadTile
	PLY : PLX
	RTS
.tile_offsets
dw $0000, $0000
dw $0080, $0000
dw $0100, $0000
;--------------------------------------------------------------------------------
QueueItemDMA:
	LDA.b #Shopkeeper_UploadVRAMTilesLong>>0 : STA !NMI_AUX
	LDA.b #Shopkeeper_UploadVRAMTilesLong>>8 : STA !NMI_AUX+1
	LDA.b #Shopkeeper_UploadVRAMTilesLong>>16 : STA !NMI_AUX+2
RTS
;--------------------------------------------------------------------------------
; X - Tile Buffer Offset
; Y - Item ID
LoadTile:
	TXA : !ADD.w !FREE_TILE_BUFFER : STA !TILE_UPLOAD_OFFSET_OVERRIDE ; load offset from X
	SEP #$30 ; set 8-bit accumulator & index registers
	TYA ; load item ID from Y
	JSL.l GetSpriteID ; convert loot id to sprite id
	JSL.l GetAnimatedSpriteTile_variable
	REP #$10 ; set 16-bit index registers
RTS
;--------------------------------------------------------------------------------
;!SHOP_INVENTORY, X
;[id][$lo][$hi][purchase_counter]
;--------------------------------------------------------------------------------
;!SHOP_PURCHASE_COUNTS = "$7EF302"
;--------------------------------------------------------------------------------
Shopkeeper_UploadVRAMTilesLong:
	JSR.w Shopkeeper_UploadVRAMTiles
RTL
Shopkeeper_UploadVRAMTiles:
		LDA $4300 : PHA ; preserve DMA parameters
		LDA $4301 : PHA ; preserve DMA parameters
		LDA $4302 : PHA ; preserve DMA parameters
		LDA $4303 : PHA ; preserve DMA parameters
		LDA $4304 : PHA ; preserve DMA parameters
		LDA $4305 : PHA ; preserve DMA parameters
		LDA $4306 : PHA ; preserve DMA parameters
		;--------------------------------------------------------------------------------
		LDA #$01 : STA $4300 ; set DMA transfer direction A -> B, bus A auto increment, double-byte mode
		LDA #$18 : STA $4301 ; set bus B destination to VRAM register
		LDA #$80 : STA $2115 ; set VRAM to increment by 2 on high register write
		
		LDA #$80 : STA $4302 ; set bus A source address to tile buffer
		LDA #$A1 : STA $4303
		LDA #$7E : STA $4304

		LDA !SHOP_TYPE : AND.b #$10 : BNE .special
		BRL .normal

	.special

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$40 : STA $2116 ; set VRAM register destination address
		LDA #$5A : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$40 : STA $2116 ; set VRAM register destination address
		LDA #$5B : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$60 : STA $2116 ; set VRAM register destination address
		LDA #$5A : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$60 : STA $2116 ; set VRAM register destination address
		LDA #$5B : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$80 : STA $2116 ; set VRAM register destination address
		LDA #$5A : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer

		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$80 : STA $2116 ; set VRAM register destination address
		LDA #$5B : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		BRL .end

	.normal
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$60 : STA $2116 ; set VRAM register destination address
		LDA #$5C : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$60 : STA $2116 ; set VRAM register destination address
		LDA #$5D : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$80 : STA $2116 ; set VRAM register destination address
		LDA #$5C : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$80 : STA $2116 ; set VRAM register destination address
		LDA #$5D : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$A0 : STA $2116 ; set VRAM register destination address
		LDA #$5C : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		
		LDA #$40 : STA $4305 : STZ $4306 ; set transfer size to 0x40
		LDA #$A0 : STA $2116 ; set VRAM register destination address
		LDA #$5D : STA $2117
		LDA #$01 : STA $420B ; begin DMA transfer
		;--------------------------------------------------------------------------------
	.end
		PLA : STA $4306 ; restore DMA parameters
		PLA : STA $4305 ; restore DMA parameters
		PLA : STA $4304 ; restore DMA parameters
		PLA : STA $4303 ; restore DMA parameters
		PLA : STA $4302 ; restore DMA parameters
		PLA : STA $4301 ; restore DMA parameters
		PLA : STA $4300 ; restore DMA parameters
RTS
;--------------------------------------------------------------------------------
Shopkepeer_CallOriginal:
	PLA : PLA : PLA
	LDA.b #ShopkeeperJumpTable>>16 : PHA
	LDA.b #ShopkeeperJumpTable>>8 : PHA
	LDA.b #ShopkeeperJumpTable : PHA
    LDA $0E80, X
    JML.l UseImplicitRegIndexedLocalJumpTable
;--------------------------------------------------------------------------------
;!SHOP_TYPE = "$7F5051"
;!SHOP_CAPACITY = "$7F5020"
;!SCRATCH_TEMP_X = "$7F5021"
Sprite_ShopKeeperPotion:
	PHB : PHK : PLB ;; we can just call the default shopkeeper but the potion shopkeeper refills your health
		LDA $A0 : CMP.b #$09 : BNE + 
			JSR.w Shopkeeper_DrawItems
			JSR.w Shopkeeper_SetupHitboxes
		+
	PLB
RTL
Sprite_ShopKeeper:
	
	LDA.l !SHOP_TYPE : CMP.b #$FF : BNE + : JMP.w Shopkepeer_CallOriginal : +
	
	PHB : PHK : PLB
		JSL.l Sprite_PlayerCantPassThrough
		
		; Draw Shopkeeper
		JSR.w Shopkeeper_DrawMerchant
		
		LDA.l !SHOP_TYPE : BIT.b #$80 : BEQ .normal ; Take-any
			BIT.b #$20 : BNE + ; Not A Take-All
			PHX
				LDA !SHOP_SRAM_INDEX : TAX
				LDA !SHOP_PURCHASE_COUNTS, X : BEQ ++ : PLX : BRA .done : ++
			PLX
			BRA .normal
		+ ; Take-All
			;PHX
			;	LDA !SHOP_SRAM_INDEX : TAX
			;	LDA.w !SHOP_PURCHASE_COUNTS, X : STA.l !SHOP_STATE
			;PLX
		.normal
		
		; Draw Items
		JSR.w Shopkeeper_DrawItems
		
		; Set Up Hitboxes
		JSR.w Shopkeeper_SetupHitboxes
		
		; $22
		; 0x48 - Left
		; 0x60 - Midpoint 1
		; 0x78 - Center
		; 0x90 - Midpoint 2
		; 0xA8 - Right
		.done
	PLB
RTL
;--------------------------------------------------------------------------------
macro DrawMerchant(head,body,speed)
	PHX : LDX.b #$00
	LDA $1A : AND <speed> : BEQ +
		-
			LDA.w .oam_shopkeeper_f1, X : STA !BIGRAM, X : INX
		CPX.b #$10 : !BLT -
	+
		-
			LDA.w .oam_shopkeeper_f2, X : STA !BIGRAM, X : INX
		CPX.b #$10 : !BLT -
	++
	PLX
	
	LDA !SHOP_MERCHANT : LSR #4 : AND.b #$0E : ORA !BIGRAM+5 : STA !BIGRAM+5
	LDA !SHOP_MERCHANT : LSR #4 : AND.b #$0E : ORA !BIGRAM+13 : STA !BIGRAM+13
	
	PHB
		LDA.b #$02 : STA $06 ; request 2 OAM slots
		LDA #$08 : JSL.l OAM_AllocateFromRegionA ; request 8 bytes
		STZ $07
	
		LDA.b #!BIGRAM : STA $08
		LDA.b #!BIGRAM>>8 : STA $09
		LDA.b #$7E : PHA : PLB ; set data bank to $7E
		JSL.l Sprite_DrawMultiple_quantity_preset
		LDA $90 : !ADD.b #$04*2 : STA $90 ; increment oam pointer
		LDA $92 : INC #2 : STA $92
	PLB
RTS
.oam_shopkeeper_f1
dw 0, -8 : db <head>, $00, $00, $02
dw 0, 0 : db <body>, $00, $00, $02
.oam_shopkeeper_f2
dw 0, -8 : db <head>, $00, $00, $02
dw 0, 0 : db <body>, $40, $00, $02
endmacro
;--------------------------------------------------------------------------------
Shopkeeper_DrawMerchant:
	LDA.l !SHOP_MERCHANT : AND.b #$07
	BEQ Shopkeeper_DrawMerchant_Type0
	CMP.b #$01 : BNE + : BRL Shopkeeper_DrawMerchant_Type1 : +
	CMP.b #$02 : BNE + : BRL Shopkeeper_DrawMerchant_Type2 : +
	CMP.b #$03 : BNE + : BRL Shopkeeper_DrawMerchant_Type3 : +
	CMP.b #$04 : BNE + : RTS : +
;--------------------------------------------------------------------------------
Shopkeeper_DrawMerchant_Type0:
%DrawMerchant(#$00, #$10, #$10)
;--------------------------------------------------------------------------------
Shopkeeper_DrawMerchant_Type1:
	LDA.b #$01 : STA $06 ; request 1 OAM slot
	LDA #$04 : JSL.l OAM_AllocateFromRegionA ; request 4 bytes
	STZ $07
	LDA $1A : AND #$08 : BEQ +
		LDA.b #.oam_shopkeeper_f1 : STA $08
		LDA.b #.oam_shopkeeper_f1>>8 : STA $09
		BRA ++
	+
		LDA.b #.oam_shopkeeper_f2 : STA $08
		LDA.b #.oam_shopkeeper_f2>>8 : STA $09
	++
	JSL.l Sprite_DrawMultiple_quantity_preset
	LDA $90 : !ADD.b #$04 : STA $90 ; increment oam pointer
	LDA $92 : INC : STA $92
RTS
.oam_shopkeeper_f1
dw 0, 0 : db $46, $0A, $00, $02
.oam_shopkeeper_f2
dw 0, 0 : db $46, $4A, $00, $02
;--------------------------------------------------------------------------------
Shopkeeper_DrawMerchant_Type2:
%DrawMerchant(#$84, #$10, #$40)
;--------------------------------------------------------------------------------
Shopkeeper_DrawMerchant_Type3:
%DrawMerchant(#$8E, #$10, #$40)
;--------------------------------------------------------------------------------
Shopkeeper_SetupHitboxes:
	PHX : PHY : PHP
	LDY.b #$00
	-
		PHY
			TYA : LSR #2 : TAY
			LDA.l !SHOP_STATE : AND.w Shopkeeper_ItemMasks, Y : BEQ +
				PLY : BRA .no_interaction
			+
		PLY
		LDA $00EE : CMP $0F20, X : BNE .no_interaction  

		JSR.w Setup_LinksHitbox
		JSR.w Setup_ShopItemCollisionHitbox
		JSL.l Utility_CheckIfHitBoxesOverlapLong
		BCC .no_contact
		    JSR.w Sprite_HaltSpecialPlayerMovementCopied
		.no_contact

		JSR.w Setup_ShopItemInteractionHitbox
		JSL.l Utility_CheckIfHitBoxesOverlapLong : BCC .no_interaction
			LDA $02DA : BNE .no_interaction ; defer if link is buying a potion (this is faster than the potion buying speed before potion shop shuffle)
		    LDA $F6 : AND.b #$80 : BEQ .no_interaction ; check for A-press
			LDA $10 : CMP.b #$0C : !BGE .no_interaction ; don't interact in other modes besides game action
			JSR.w Shopkeeper_BuyItem
		.no_interaction
		INY #4
	TYA : CMP !SHOP_CAPACITY : !BLT -
	;CPY.b #$0C : !BLT -
	
	PLP : PLY : PLX
RTS

GetFunnyBottleFunction:
	; A = contents - 3 (red, green, blue, fairy, bee, goldbee)
	PHX : PHA
	LDA $7EF34F : BEQ .noBottle : TAX : DEX : PLA : !ADD #$3 : PHA
	CMP $7EF35C, X : BNE .noBottle
	.hasBottle : PLA : INX : TXA : PLX : RTS
	.noBottle : PLA : PLX : LDA #$0 : RTS
!LOCK_STATS = "$7EF443"
!ITEM_TOTAL = "$7EF423"
;--------------------
;!SHOP_STATE
Shopkeeper_BuyItem:
	PHX : PHY
		TYX

		LDA.l !SHOP_INVENTORY, X
		CMP.b #$0E : BEQ .refill ; Bee Refill
		CMP.b #$2E : BEQ .refill ; Red Potion Refill
		CMP.b #$2F : BEQ .refill ; Green Potion Refill
		CMP.b #$30 : BEQ .refill ; Blue Potion Refill
		CMP.b #$B2 : BEQ .refill ; Good Bee Refill
		BRA +
			.refill
			LDA #$1 : STA !SHOP_KEEP_REFILL ; If this is on, don't toggle bit to remove from shop
			JSL.l Sprite_GetEmptyBottleIndex : BPL + : BRL .full_bottles
		+

		LDA !SHOP_TYPE : AND.b #$80 : BEQ + : BRL .buy : + ; don't charge if this is a take-any

		.custom_price
		LDA !SHOP_INVENTORY+2, X : AND.b #$80 : BNE .price_is_not_rupees ; i honestly can't think of a better way to do this block because i haven't done asm in like 8 months
		 		JMP .price_is_rupees
			.price_is_not_rupees
			LDA !SHOP_INVENTORY+2, X : AND.b #$7F : CMP.b #$09 : BNE + ; 09 specifically is item
				LDA !SHOP_INVENTORY+1, X : CMP.b $0303 : BNE .gotItem
					BRL .cant_afford
				.gotItem ; hand it over??  not logic friendly
				BRL .buy_real
			+
		 	CMP.b #$08 : BNE + ; 08 specifically is potion
				LDA !SHOP_INVENTORY+1, X : JSR GetFunnyBottleFunction : CMP #$0 : BNE .gotBottle
					BRL .cant_afford
				.gotBottle
				PHX : LDA $7EF34F : TAX : DEX : LDA #$02 : STA $7EF35C, X : PLX : BRL .buy_real
			+
			LDA !SHOP_INVENTORY+2, X : AND.b #$07 ; if bit 80, it's custom, if numbers 0-7, custom resource
				; store shop index, get resource offset (X), load val, pop shop index, cmp val to shop_price...
				PHX : TAX : LDA ResourceOffset, X : TAX : TAY : LDA $7EF300, X ; fumble around with our resource value and price, sub value then put back into RAM
				PLX : CMP !SHOP_INVENTORY+1,X : BMI + ; if resource is less than value, skip
				; If hearts, ensure hearts are greater than the price
				BNE .notEqual : CPY #$6D : BEQ .cant_afford
				.notEqual
				; subtract and store, store (x), store val back to address
				; if X is heart containers, set ordinary hearts
				!SUB !SHOP_INVENTORY+1,X : PHX : TYX : STA $7EF300, X
				CPX #$6C : BNE .notHeartContainers
					CMP $7EF36D : !BGE .notHeartContainers : STA $7EF36D
				.notHeartContainers
				PLX : BRL .buy_real
			+
		 	BRL .cant_afford
		.price_is_rupees

		REP #$20 : LDA $7EF360 : CMP.l !SHOP_INVENTORY+1, X : SEP #$20 : !BGE .buy
		
		.cant_afford
	        LDA.b #$7A
	        LDY.b #$01
	        JSL.l Sprite_ShowMessageUnconditional
			LDA.b #$3C : STA $012E ; error sound
			BRL .done
			.full_bottles
				LDA.b #$6B
				LDY.b #$01
				JSL.l Sprite_ShowMessageUnconditional
				LDA.b #$3C : STA $012E ; error sound
				BRL .done
		.buy
			LDA !SHOP_TYPE : AND.b #$80 : BNE ++ ; don't charge if this is a take-any
				REP #$20 : LDA $7EF360 : !SUB !SHOP_INVENTORY+1, X : STA $7EF360 : SEP #$20 ; Take price away
			++
		.buy_real
			print "Shop Check: ", pc
			PHX
				LDA #0 : XBA : TXA : LSR #2 : TAX : LDA.l !SHOP_INVENTORY_PLAYER, X : STA !MULTIWORLD_ITEM_PLAYER_ID
				LDA.l !SHOP_TYPE : BIT.b #$80 : BNE +		;Is the shop location a take-any cave
				TXA : !ADD !SHOP_SRAM_INDEX : TAX : BRA ++				;If so, explicitly load first SRAM Slot.

				+ LDA.l !SHOP_SRAM_INDEX : TAX
				
				++ LDA.l !SHOP_PURCHASE_COUNTS, X : BNE +++	;Is this the first time buying this slot?
				LDA.l EnableShopItemCount, X : STA.l !SHOP_ENABLE_COUNT ; If so, store the permission to count the item here.
				+++
			PLX
			LDA.l !SHOP_INVENTORY, X : TAY : JSL.l Link_ReceiveItem
			LDA.l !SHOP_INVENTORY+3, X : INC : STA.l !SHOP_INVENTORY+3, X
			LDA.b #0 : STA.l !SHOP_ENABLE_COUNT

			TXA : LSR #2 : TAX
			LDA !SHOP_TYPE : BIT.b #$80 : BNE +
				LDA !SHOP_KEEP_REFILL : BNE +++
				LDA.l !SHOP_STATE : ORA.w Shopkeeper_ItemMasks, X : STA.l !SHOP_STATE
				+++
				PHX
					TXA : !ADD !SHOP_SRAM_INDEX : TAX

					LDA !SHOP_PURCHASE_COUNTS, X : INC : BEQ +++ : STA !SHOP_PURCHASE_COUNTS, X : +++
					
					LDA.l RetroArrowShopBoughtMask, X : BEQ ++++ ; Confirm purchase was of a retro single arrow slot.
					LDA.l RetroArrowShopList : PHX : TAX : LDA.l !SHOP_PURCHASE_COUNTS, X : BEQ +++ : PLX : BRA ++++ : +++ : PLX ; Check to see if all shop locationss already marked.
					
					LDA.l RetroArrowShopBoughtMask, X : BEQ ++++ : ORA.l !SHOP_STATE : STA.l !SHOP_STATE ; Prevent purchase of other single arrows in same shop.
					LDX #$00
					- LDA.l RetroArrowShopList, X : BMI ++++ ; If end of list, stop here.
						PHX : TAX
							LDA !SHOP_PURCHASE_COUNTS, X : BNE +++
							INC : STA !SHOP_PURCHASE_COUNTS, X
							
							LDA !LOCK_STATS : BNE +++
							LDA.l EnableShopItemCount, X : BEQ +++
							REP #$20 : LDA !ITEM_TOTAL : INC : STA !ITEM_TOTAL : SEP #$20
						+++
						PLX
						INX
					BRA -
					++++
				PLX
				BRA ++
			+ ; Take-any
			;STA $FFFFFF
				BIT.b #$20 : BNE .takeAll
				.takeAny
					LDA.l !SHOP_STATE : ORA.b #$07 : STA.l !SHOP_STATE
					PHX
						LDA.l !SHOP_SRAM_INDEX : TAX : LDA.b #$01 : STA.l !SHOP_PURCHASE_COUNTS, X
					PLX
					BRA ++
				.takeAll
					LDA.l !SHOP_STATE : ORA.w Shopkeeper_ItemMasks, X : STA.l !SHOP_STATE
					PHX
						LDA.l !SHOP_SRAM_INDEX : TAX : LDA.l !SHOP_STATE : STA.l !SHOP_PURCHASE_COUNTS, X
					PLX
			++
			; JSL.l ReloadShopkeep
	.done
	LDA #$0 : STA !SHOP_KEEP_REFILL
	PLY : PLX
RTS
ReloadShopkeep:
	PHX : PHY : PHP
	REP #$30 ; set 16-bit accumulator & index registers
	JMP SpritePrep_ShopKeeper_success
Shopkeeper_ItemMasks:
db #$01, #$02, #$04, #$08
;--------------------
;!SHOP_ID = "$7F5050"
;!SHOP_SRAM_INDEX = "$7F5062"
;!SHOP_PURCHASE_COUNTS = "$7EF302"
;--------------------
Setup_ShopItemCollisionHitbox:
;The complications with XBA are to handle the fact that nintendo likes to store
;high and low bytes of 16 bit postion values seperately :-(

	REP #$20 ; set 16-bit accumulator
	LDA $00 : PHA
	SEP #$20 ; set 8-bit accumulator

    ; load shopkeeper X (16 bit)
    LDA $0D30, X : XBA : LDA $0D10, X
	
	REP #$20 ; set 16-bit accumulator
	PHA : PHY
		LDA !SHOP_TYPE : AND.w #$0003 : DEC : ASL : TAY
		LDA $A0 : CMP.l #$109 : BNE + : INY #6 : + 
		LDA.w Shopkeeper_DrawNextItem_item_offsets_idx, Y : STA $00 ; get table from the table table
	PLY : PLA
    
    !ADD ($00), Y
    !ADD.w #$0002 ; a small negative margin
    ; TODO: add 4 for a narrow item
    SEP #$20 ; set 8-bit accumulator

    ; store hitbox X 
    STA $04 : XBA : STA $0A 

    ;load shopkeeper Y (16 bit)
    LDA $0D20, X : XBA : LDA $0D00, X 

    REP #$20 ; set 16-bit accumulator
    PHY : INY #2
		!ADD ($00), Y
	PLY
	PHA : LDA !SHOP_TYPE : AND.w #$0080 : BEQ + ; lower by 4 for Take-any
		PLA : !ADD.w #$0004
		BRA ++
	+ : PLA : ++
    SEP #$20 ; set 8-bit accumulator

    ; store hitbox Y Low: $05, High $0B
    STA $05 : XBA : STA $0B 

    LDA.b #12 : STA $06 ; Hitbox width, always 12 for existing (wide) shop items
    ; TODO: for narrow sprite store make width 4 (i.e. 8 pixels smaller)

    LDA.b #14 : STA $07 ; Hitbox height, always 14
	
	REP #$20 ; set 16-bit accumulator
	PLA : STA $00
	SEP #$20 ; set 8-bit acc
RTS
;--------------------------------------------------------------------------------
; Adjusts the already set up collision hitbox to be a suitable interaction hitbox
Setup_ShopItemInteractionHitbox:
	PHP
	SEP #$20 ; set 8-bit accumulator
	
    ; collision hitbox has left margin of -2, we want margin of 8 so we subtract 10
    LDA $04 : !SUB.b #$0A : STA $04
    LDA $0A : SBC.b #$00 : STA $0A ; Apply borrow

    ; collision hitbox has 0 top margin, we want a margin of 8 so we subtract 8
    LDA $05 : !SUB.b #$08 : STA $05
    LDA $0B : SBC.b #$00 : STA $0B ; Apply borrow    

    ; We want a width of 32 for wide or 24 for narrow, so we add 20
    LDA $06 : !ADD.b #20 : STA $06 ; Hitbox width

    LDA.b #40 : STA $07 ; Hitbox height, always 40
	PLP
RTS
;--------------------------------------------------------------------------------
; Following is a copy of procedure $3770A (Bank06.asm Line 6273) 
; because there is no long version available
Setup_LinksHitbox:
	LDA.b #$08 : STA $02
                     STA $03
        
        LDA $22 : !ADD.b #$04 : STA $00
        LDA $23 : ADC.b #$00 : STA $08
        
        LDA $20 : ADC.b #$08 : STA $01
        LDA $21 : ADC.b #$00 : STA $09     
RTS
;--------------------------------------------------------------------------------
; The following is a copy of procedure Sprite_HaltSpecialPlayerMovement (Bank1E.asm line 255)
; because there is no long version available
Sprite_HaltSpecialPlayerMovementCopied:
        PHX      
        JSL Sprite_NullifyHookshotDrag
        STZ $5E ; Set Link's speed to zero...
        JSL Player_HaltDashAttackLong
        PLX
RTS
;--------------------------------------------------------------------------------
;!SHOP_TYPE = "$7F5051"
;!SHOP_INVENTORY = "$7F5052"
!SPRITE_OAM = "$7EC025"
!REDRAW = "$7F5000"
Shopkeeper_DrawItems:
	PHB : PHK : PLB
	PHX : PHY
	TXA : STA !SCRATCH_TEMP_X;
	
	LDX.b #$00
	LDY.b #$00
	LDA !SHOP_TYPE : AND.b #$03
	CMP.b #$03 : BNE +
		JSR.w Shopkeeper_DrawNextItem : BRA ++
	+ CMP.b #$02 : BNE + : ++
		JSR.w Shopkeeper_DrawNextItem : BRA ++
	+ CMP.b #$01 : BNE + : ++
		JSR.w Shopkeeper_DrawNextItem
	+
	LDA $A0 : CMP.b #$09 : BNE + ; render powder slot if potion shop
	LDA !REDRAW : BNE + ; if not redrawing
	LDA $02DA : BNE + ; if not buying item
	LDA $7F505E : BEQ + ; if potion slot filled
	LDA $0ABF : BEQ + ; haven't left the room
	LDA !NPC_FLAGS_2 : AND.b #$20 : BNE + 
		LDX.b #$0C : LDY.b #$03 : JSR.w Shopkeeper_DrawNextItem
	+
	PLY : PLX
	PLB
RTS

;--------------------------------------------------------------------------------
Shopkeeper_DrawNextItem:
	LDA.l !SHOP_STATE : AND.w Shopkeeper_ItemMasks, Y : BEQ + : BRL .next : +
	
	PHY
	
	LDA !SHOP_TYPE : AND.b #$03 : DEC : ASL : TAY
	REP #$20 ; set 16-bit accumulator
	LDA $A0 : CMP.l #$109 : BNE + : INY #6 : +
	LDA.w .item_offsets_idx, Y : STA $00 ; get table from the table table
	LDA 1,s : ASL #2 : TAY ; set Y to the item index
	LDA ($00), Y : STA.l !SPRITE_OAM ; load X-coordinate
	INY #2
	LDA !SHOP_TYPE : AND.w #$0080 : BNE +
		LDA ($00), Y : STA.l !SPRITE_OAM+2 : BRA ++ ; load Y-coordinate
	+
		LDA ($00), Y : !ADD.w #$0004 : STA.l !SPRITE_OAM+2 ; load Y-coordinate
	++
	SEP #$20 ; set 8-bit accumulator
	PLY
	
	PHX : LDA #0 : XBA : TXA : LSR #2 : TAX : LDA.l !SHOP_INVENTORY_DISGUISE, X : PLX : CMP #$0 : BNE ++ 
		LDA.l !SHOP_INVENTORY, X ; get item palette
	++
	CMP.b #$2E : BNE + : BRA .potion
	+ CMP.b #$2F : BNE + : BRA .potion
	+ CMP.b #$30 : BEQ .potion
	CMP.b #$B1 : BEQ .fae
	CMP.b #$B3 : BEQ .jar
	CMP.b #$B4 : BEQ .apple
	.normal
		LDA.w .tile_indices, Y : BRA + ; get item gfx index
	.potion
		LDA.b #$C0 ; potion is #$C0 because it's already there in VRAM
		BRA +
	.fae
		LDA.b #$EA ; already there in VRAM
		BRA +
	.jar
		LDA.b #$62 ; already there in VRAM
		BRA +
	.apple
		LDA.b #$E5 ; already there in VRAM
	+
	XBA

	LDA !SHOP_TYPE : AND.b #$10 : BEQ +
		XBA : !SUB #$22 : XBA ; alt vram
	+
	XBA

	STA.l !SPRITE_OAM+4

	PHX : LDA #0 : XBA : TXA : LSR #2 : TAX : LDA.l !SHOP_INVENTORY_DISGUISE, X : PLX : CMP #$0 : BNE ++ 
		LDA.l !SHOP_INVENTORY, X ; get item palette
	++
	JSL.l GetSpritePalette : STA.l !SPRITE_OAM+5

	LDA.l !SPRITE_OAM+4 : CMP #$EA : BEQ .swap_sheet : CMP #$E4 : BEQ .swap_sheet : CMP #$62 : BEQ .swap_sheet : CMP #$E5 : BEQ .swap_sheet
	AND #$FE : STA.l !SPRITE_OAM+4 ; if normal indices, strip last bit so it's even on the sprite sheet
	LDA.w .tile_indices, Y : AND.b #$01 : BEQ +; get tile index sheet (swap sheet if we're using the upper tiles)
		.swap_sheet
		LDA.l !SPRITE_OAM+5
		ORA.b #$1
		STA.l !SPRITE_OAM+5
	+

	LDA.b #$00 : STA.l !SPRITE_OAM+6

	PHX : LDA #0 : XBA : TXA : LSR #2 : TAX : LDA.l !SHOP_INVENTORY_DISGUISE, X : PLX : CMP #$0 : BNE ++ 
		LDA.l !SHOP_INVENTORY, X ; get item id for narrowness
	++
	JSL.l IsNarrowSprite : BCS .narrow
	.full
		LDA.b #$02
		STA.l !SPRITE_OAM+7
		LDA.b #$01
		BRL ++
	.single
		LDA.b #$00
		STA.l !SPRITE_OAM+7
		JSR.w PrepNarrowLower
		LDA.b #$01
		BRA ++
	.narrow
		LDA.b #$00
		STA.l !SPRITE_OAM+7
		JSR.w PrepNarrowLower
		LDA.b #$02
	++
	PHX : PHA : LDA !SCRATCH_TEMP_X : TAX : PLA : JSR.w RequestItemOAM : PLX
	
	LDA !SHOP_TYPE : AND.b #$80 : BNE +
	CPX.b #12 : BEQ + ; don't render potion price
		JSR.w Shopkeeper_DrawNextPrice
	+
	
	.next
	INY
	INX #4
RTS
;--------------------------------------------------------------------------------
.item_offsets_idx ; 112 60
dw #.item_offsets_1
dw #.item_offsets_2
dw #.item_offsets_3
.item_offsets_idx_Potion ; 160 176 - (112 64) = (48 112)
dw #.item_offsets_1p
dw #.item_offsets_2p
dw #.item_offsets_3p
.item_offsets_1
dw 8, 40
.item_offsets_2
dw -16, 40
dw 32, 40
.item_offsets_3
dw -40, 40
dw 8, 40
dw 56, 40
.item_offsets_1p
dw -40, -72
.item_offsets_2p
dw -64, -72
dw -16, -72
.item_offsets_3p
dw -88, -72
dw -40, -72
dw 8, -72
.potion_offset
dw -16, 0
.tile_indices
db $C6, $C8, $CA, $25 ; last bit is for sheet change
;--------------------------------------------------------------------------------
!COLUMN_LOW = "$7F5022"
!COLUMN_HIGH = "$7F5023"
Shopkeeper_DrawNextPrice:
	PHB : PHK : PLB
	PHX : PHY : PHP
	
	REP #$20 ; set 16-bit accumulator
	PHY
		LDA !SHOP_TYPE : AND.w #$0003 : DEC : ASL : TAY
		LDA $A0 : CMP.l #$109 : BNE + : INY #6 : + 
		LDA.w Shopkeeper_DrawNextItem_item_offsets_idx, Y : STA $00 ; get table from the table table
		LDA.w .price_columns_idx, Y : STA $02 ; get table from the table table
	PLY : PHY
		TYA : ASL #2 : TAY
		LDA ($00), Y : STA $0E ; set coordinate
		TYA : LSR : TAY
		LDA ($02), Y : STA !COLUMN_LOW
		INY : LDA ($02), Y : STA !COLUMN_HIGH
	PLY
	LDA.l !SHOP_INVENTORY+1, X : STA $0C ; set value
	
	JSR.w DrawPrice
	SEP #$20 : STA $06 : STZ $07 ; set 8-bit accumulator & store result
	PHA
		LDA.b #!BIGRAM : STA $08
		LDA.b #!BIGRAM>>8 : STA $09
		LDA.b #$7E : PHA : PLB ; set data bank to $7E

		PHX : PHA : LDA !SCRATCH_TEMP_X : TAX : PLA : JSL.l Sprite_DrawMultiple_quantity_preset : PLX
	
		LDA 1,s
		ASL #2 : !ADD $90 : STA $90 ; increment oam pointer
	PLA
	!ADD $92 : STA $92
	PLP : PLY : PLX
	PLB
RTS
.price_columns_idx
dw #.price_columns_1
dw #.price_columns_2
dw #.price_columns_3
.price_columns_1
db #$00, #$FF
.price_columns_2
db #$00, #$80, #$80, $FF
.price_columns_3
db #$00, #$60, #$60, #$90, #$90, $FF, $FF, $FF
;--------------------------------------------------------------------------------
RequestItemOAM:
	PHX : PHY : PHA
		STA $06 ; request A OAM slots
		LDA $20 : CMP.b #$62 : !BGE .below
			.above
			LDA 1,s : ASL #2 : JSL.l OAM_AllocateFromRegionA ; request 4A bytes
			BRA +
			.below
			LDA 1,s : ASL #2 : JSL.l OAM_AllocateFromRegionB ; request 4A bytes
		+
		LDA 1,s  : STA $06 ; request 3 OAM slots
		STZ $07
		LDA.b #!SPRITE_OAM : STA $08
		LDA.b #!SPRITE_OAM>>8 : STA $09
		LDA #$7E : PHB : PHA : PLB
			JSL Sprite_DrawMultiple_quantity_preset
		PLB
		LDA 1,s : ASL #2 : !ADD $90 : STA $90 ; increment oam pointer
		LDA $92 : !ADD 1,s : STA $92
	PLA : PLY : PLX
RTS
;--------------------------------------------------------------------------------
PrepNarrowLower:
	PHX
	LDX.b #$00
		REP #$20 ; set 16-bit accumulator
		LDA !SPRITE_OAM, X : !ADD.w #$0004 : STA !SPRITE_OAM, X : STA !SPRITE_OAM+8, X
		LDA !SPRITE_OAM+2, X : !ADD.w #$0008 : STA !SPRITE_OAM+10, X
		LDA !SPRITE_OAM+4, X : !ADD.w #$0010 : STA !SPRITE_OAM+12, X
		LDA !SPRITE_OAM+6, X : STA !SPRITE_OAM+14, X
		SEP #$20 ; set 8-bit accumulator
	PLX
RTS
;--------------------------------------------------------------------------------
;.oam_items
;dw -40, 40 : db $C0, $08, $00, $02
;dw 8, 40 : db $C2, $04, $00, $02
;dw 56, 40 : db $C4, $02, $00, $02
;--------------------------------------------------------------------------------
;.oam_prices
;dw -48, 56 : db $30, $02, $00, $00
;dw -40, 56 : db $31, $02, $00, $00
;dw -32, 56 : db $02, $02, $00, $00
;dw -24, 56 : db $03, $02, $00, $00
;
;dw 0, 56 : db $12, $02, $00, $00
;dw 8, 56 : db $13, $02, $00, $00
;dw 16, 56 : db $22, $02, $00, $00
;dw 24, 56 : db $23, $02, $00, $00
;
;dw 48, 56 : db $32, $02, $00, $00
;dw 56, 56 : db $33, $02, $00, $00
;dw 64, 56 : db $30, $02, $00, $00
;dw 72, 56 : db $31, $02, $00, $00
;--------------------------------------------------------------------------------
