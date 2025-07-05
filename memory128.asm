// A Memory Game for the Commodore C128 80 col VDC
// compiles with Kick Assembler (cross assembler)
// https://theweb.dk/KickAssembler/Main.html#frontpage

/* constants & zero page ============================================================== */

// https://github.com/franckverrot/EmulationResources/blob/master/consoles/commodore/C128%20RAM%20Map.txt
.const MMUCR    = $ff00         // bank configuration register
.const VDCWRITE = $cdcc         // kernal write to VDC 
.const VDCREAD  = $cdda         // kernal read from VDC 
.const GETIN    = $ffe4         // kernal GETIN
.const CINT     = $c000         // kernal CINT Initialize Editor & Screen

// mem locations
.const PRG      = $2030         // main prg
.const CHR_DATA = $3000         // char data main screen
.const CHR_DAT2 = $3800         // char data cards
.const CHR_DAT3 = $4000         // char data You Win!
.const VDCRAM   = $0000         // basic VDC ram
.const VDCRAM2  = $1000         // empty VDC ram
.const VDCRAM3  = $1800         // empty VDC ram 

// free zero page locations
.const temp1    = $fa           // to store temp values
.const temp2    = $fb           // to store temp values 
.const temp3    = $fc           // to store temp values 
.const temp4    = $fd           // to store temp values

// variables
src_low:        .byte 0         // low byte of the source
src_high:       .byte 0         // high byte of the source
dst_low:        .byte 0         // low byte of the destination
dst_high:       .byte 0         // high byte of the destination

// two cards are drawn and compared
// store values for card 1 and 2
src_low_crd1:   .byte 0         // low byte of the source of card 1
src_high_crd1:  .byte 0         // high byte of the source of card 1
dst_low_crd1:   .byte 0         // low byte of the destination of card 1
dst_high_crd1:  .byte 0         // high byte of the destination of card 1

src_low_crd2:   .byte 0         // low byte of the source of card 2
src_high_crd2:  .byte 0         // high byte of the source of card 2
dst_low_crd2:   .byte 0         // low byte of the destination of card 2
dst_high_crd2:  .byte 0         // high byte of the destination of card 2

// a match of two cards is the sum of two card values which is 255 in case of a match
match:          .byte 0         // two cards have matched if match is 255
match_cnt:      .byte 0         // how many card have been drawn
value_1:        .byte 0         // card value of card 1
value_2:        .byte 0         // card value of card 2

score:          .byte 0         // high score
param:          .byte 0         // for decimal output of the score

jump_addr:      .word $0000     // jump location after pressing a specific key

.var            ts  = 1         // time before cards flip or vanish seconds +
.var            t10 = 3         // time before cards flip or vanish 1/10 seconds
/* ==================================================================================== */

BasicUpstart128(start)

*=PRG "Program"

/* start ============================================================================== */
start:
    jsr CINT                    // initialize editor & screen
    lda #$06                    // bank id 12 for more ram
    sta MMUCR                   // tell mmu to switch bank
    
    // prepare sid to get random numbers
    // https://www.atarimagazines.com/compute/issue72/random_numbers.php
    // https://codebase64.net/doku.php?id=base:noise_waveform
    // Mapping the Commodore C128
    lda #%10001111              // disconnect voice3 from output, set max volume
    sta $d418                   // store in volume and filter mod reg
    lda #$08                    // test bit to reset wave form
    sta $d412                   // voice 3 control register
    // generate random cards during compile time
    // by changing the frequency for the noise waveform
    // random cards during run time -> see below
    .var freq = round(random()*$FFFF)
    lda #<freq                  // maximum frequency value low byte
    sta $d40e                   // voice 3 frequency low byte
    lda #>freq                  // maximum frequency value high byte
    sta $d40f                   // voice 3 frequency high byte
    lda #$80                    // noise waveform, gate bit off
    sta $d412                   // voice 3 control register

/* load screen data to ram ============================================================ */
// prepare loading chars
// src 1: char data
// cards back
    lda #0                      // load 0
    sta temp1                   // counter inner loop
    sta temp2                   // counter outer loop
    lda #<CHR_DATA              // load src 1 (chars) lb
    sta temp3                   // store src 1 (chars) lb
    lda #>CHR_DATA              // load src 1 (chars) hb 
    sta temp4                   // store src 1 (chars) hb 
    ldy #0                      // load 0


    ldx #18                     // register of screen addr high byte 
    lda #>VDCRAM                // load VDC high byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #19                     // register of screen addr low byte 
    lda #<VDCRAM                // load VDC low byte
    jsr VDCWRITE                // kernal to write to VDC
    
// loop to load all chars
loop_ch:
    ldx #31                     // data register of VDC
    ldy temp1                   // inner counter for screen char data
    lda (temp3),y               // load char to VDC data register from src 1
    jsr VDCWRITE                // kernal to write to VDC
    inc temp1                   // increment temp1
    bne loop_ch                 // -> 255 exit inner loop
        
    inc temp4                   // increment high byte src 1
    inc temp2                   // counter outer loop
    lda temp2                   // load counter outer loop
    cmp #8                      // is it 8 (x 256) ?
    bne loop_ch                 // = 8 ? exit loop, all chars on screen

/* load screen data to ram ============================================================ */
// src 2: char data
// card faces
    lda #0                      // load 0
    sta temp1                   // counter inner loop
    sta temp2                   // counter outer loop
    lda #<CHR_DAT2              // load src 1 (chars) lb
    sta temp3                   // store src 1 (chars) lb
    lda #>CHR_DAT2              // load src 1 (chars) hb 
    sta temp4                   // store src 1 (chars) hb 
    ldy #0                      // load 0


    ldx #18                     // register of screen addr high byte 
    lda #>VDCRAM2               // load VDC high byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #19                     // register of screen addr low byte 
    lda #<VDCRAM2               // load VDC low byte
    jsr VDCWRITE                // kernal to write to VDC
    
// loop to load all chars
loop_ch2:
    ldx #31                     // data register of VDC
    ldy temp1                   // inner counter for screen char data
    lda (temp3),y               // load char to VDC data register from src 1
    jsr VDCWRITE                // kernal to write to VDC
    inc temp1                   // increment temp1
    bne loop_ch2                // -> 255 exit inner loop

    inc temp4                   // increment high byte src 1
    inc temp2                   // counter outer loop
    lda temp2                   // load counter outer loop
    cmp #5                      // is it 8 (x 256) ?
    bne loop_ch2                 // = 8 ? exit loop, all chars on screen

/* load screen data to ram ============================================================ */
// src 3: char data
// you win screen
    lda #0                      // load 0
    sta temp1                   // counter inner loop
    sta temp2                   // counter outer loop
    lda #<CHR_DAT3              // load src 1 (chars) lb
    sta temp3                   // store src 1 (chars) lb
    lda #>CHR_DAT3              // load src 1 (chars) hb 
    sta temp4                   // store src 1 (chars) hb 
    ldy #0                      // load 0


    ldx #18                     // register of screen addr high byte 
    lda #>VDCRAM3               // load VDC high byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #19                     // register of screen addr low byte 
    lda #<VDCRAM3               // load VDC low byte
    jsr VDCWRITE                // kernal to write to VDC
    
// loop to load all chars
loop_ch3:
    ldx #31                     // data register of VDC
    ldy temp1                   // inner counter for screen char data
    lda (temp3),y               // load char to VDC data register from src 1
    jsr VDCWRITE                // kernal to write to VDC
    inc temp1                   // increment temp1
    bne loop_ch3                // -> 255 exit inner loop

    inc temp4                   // increment high byte src 1
    inc temp2                   // counter outer loop
    lda temp2                   // load counter outer loop
    cmp #8                      // is it 8 (x 256) ?
    bne loop_ch3                // = 8 ? exit loop, all chars on screen

/* shuffle / randomize cards ========================================================== */

jsr fill_unique_array           // build randomized card face & value array
jsr copy                        // rearrange the starting order of cards / shuffle cards 
    
/* main loop ========================================================================== */
main_loop:
    jsr decout                  // -> display score
    jsr check_no_cards          // -> check if there are still cards 
    jsr handle_input            // -> handle keys
    cmp #'X'                    // if acc is 'X' -> exit 
    bne main_loop               // else loop
    jsr exit                    // -> exit

/* exit prg =========================================================================== */
exit:
    lda #0                      // load 0
    sta score                   //  set score to zero
    jsr CINT                    // initialize editor & screen
    lda #$00                    // bank id 15 (default)
    sta MMUCR                   // tell mmu to switch bank
    rts                         // exit to BASIC
    
/* handle keys pressed ================================================================ */
handle_input:
    jsr GETIN                   // get pressed key from keyboard buffer
    beq no_key                  // 0 if no key is pressed -> no_key
    cmp #'X'                    // 'X' key pressed 
    beq quit_game               // -> rts to main and quit
    ldx #0                      // load '0'
search_loop:
    cmp key_table,x             // check for key in table, x is index
    beq found_key               // -> found key
    inx                         // next index
    cpx #16                     // compare index with total number of avail keys = 16
    bne search_loop             // not yet 16? -> search_loop
    rts                         // no key found after 16 -> rts 

found_key:
    txa                         // transfer index x to acc
    asl                         // * 2 (handler table is word)
                                // byte 10 in key_table is 20 in handler_table
    tax                         // transfer acc to x
    
    lda handler_table,x         // low byte handler
    sta jump_addr               // store low byte
    lda handler_table+1,x       // high byte handler
    sta jump_addr+1             // store high byte
    jmp (jump_addr)             // -> jum to show cards

// 'X' key pressed
quit_game:
    rts
// no key pressed
no_key:
    rts
// other key pressed
invalid_key:
    rts

// key table
key_table:
    .byte '1', '2', '3', '4', '5', '6', '7', '8'
    .byte 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I'

// jmp adresses table
handler_table:
    .word show_1, show_2, show_3, show_4
    .word show_5, show_6, show_7, show_8
    .word show_Q, show_W, show_E, show_R
    .word show_T, show_Y, show_U, show_I

/* select card pos, face and value ==================================================== */
// macro ShowCard(position on screen position, face & value)
// position, face & value is organized in tables
// value of a matching pair is 255
// cards (not pos.) with their values are randomized / shuffled (which is not shown here)

show_1: ShowCard(1,0)           // position  1, card  0, value 1
show_2: ShowCard(2,1)           // position  2, card  1, value 254
show_3: ShowCard(3,2)           // position  3, card  2, value 2
show_4: ShowCard(4,3)           // position  4, card  3, value 253
show_5: ShowCard(5,4)           // position  5, card  4, value 3
show_6: ShowCard(6,5)           // position  6, card  5, value 252
show_7: ShowCard(7,6)           // position  7, card  6, value 4
show_8: ShowCard(8,7)           // position  8, card  7, value 251
show_Q: ShowCard(9,8)           // position  9, card  8, value 5
show_W: ShowCard(10,9)          // position 10, card  9, value 250
show_E: ShowCard(11,10)         // position 11, card 10, value 6
show_R: ShowCard(12,11)         // position 12, card 11, value 249
show_T: ShowCard(13,12)         // position 13, card 12, value 7
show_Y: ShowCard(14,13)         // position 14, card 13, value 248
show_U: ShowCard(15,14)         // position 15, card 14, value 8
show_I: ShowCard(16,15)         // position 16, card 15, value 247

// card positions on screen
card_pos_array:  
//         y * 80 +  x + VDCRAM // position
    .word  0 * 80 +  0 + VDCRAM //  0 (not used)
    .word  1 * 80 +  1 + VDCRAM //  1
    .word  1 * 80 + 11 + VDCRAM //  2
    .word  1 * 80 + 21 + VDCRAM //  3
    .word  1 * 80 + 31 + VDCRAM //  4
    .word  1 * 80 + 41 + VDCRAM //  5
    .word  1 * 80 + 51 + VDCRAM //  6
    .word  1 * 80 + 61 + VDCRAM //  7
    .word  1 * 80 + 71 + VDCRAM //  8
    .word 13 * 80 +  1 + VDCRAM //  9
    .word 13 * 80 + 11 + VDCRAM // 10
    .word 13 * 80 + 21 + VDCRAM // 11
    .word 13 * 80 + 31 + VDCRAM // 12
    .word 13 * 80 + 41 + VDCRAM // 13
    .word 13 * 80 + 51 + VDCRAM // 14
    .word 13 * 80 + 61 + VDCRAM // 15
    .word 13 * 80 + 71 + VDCRAM // 16

// back side of the cards and empty (black) "card" or "no card"
special_card_face_array: 
    .word VDCRAM2 +  0          // 0 special, back
    .word VDCRAM2 + 64          // 1 special, empty

// card faces, value of the card; card size 8x8
// matching pair gives 255 (e.g. 2 + 253 = 255)
// start configuration that will be randomized or shuffled
card_face_origin: 
//  start address + n*8x8, card value  
    .word VDCRAM2 +  128,   1   // card  0, value 1
    .word VDCRAM2 +  192, 254   // card  1, value 254
    .word VDCRAM2 +  256,   2   // card  2, value 2
    .word VDCRAM2 +  320, 253   // card  3, value 253
    .word VDCRAM2 +  384,   3   // card  4, value 3
    .word VDCRAM2 +  448, 252   // card  5, value 252
    .word VDCRAM2 +  512,   4   // card  6, value 4
    .word VDCRAM2 +  576, 251   // card  7, value 251
    .word VDCRAM2 +  640,   5   // card  8, value 5
    .word VDCRAM2 +  704, 250   // card  9, value 250
    .word VDCRAM2 +  768,   6   // card 10, value 6
    .word VDCRAM2 +  832, 249   // card 11, value 249
    .word VDCRAM2 +  896,   7   // card 12, value 7
    .word VDCRAM2 +  960, 248   // card 13, value 248
    .word VDCRAM2 + 1024,   8   // card 14, value 8
    .word VDCRAM2 + 1088, 247   // card 15, value 247

/* randomize or shuffle cards========================================================== */

// randomize or shuffle the cards
// generate a random number
// put it in 'used'
// check if the number is already generated
// if not, put it in 'array'
fill_unique_array:
    ldx #15                     // 15 cards
    ldy #0                      // Index für array (0-15)
clear_used:                     // fill used with zero after start (otherwise error)
    lda #0                      // load zero 
    sta used,x                  // store in 'used'
    dex                         // decrement x
    bpl clear_used              // everything is zero in 'used'? -> clear used
fill_loop:
    // get new random number
find_new_number:
    lda $d41b                   // get random number (SID)
    and #$0F                    // range 0 - 15
    tax                         // use as index for 'used'
    
    lda used,x                  // check if already generated
    bne find_new_number         // if yes -> generate new random number
    
    // new random number
    lda #1                       // mark as used
    sta used,x                   // put in 'used'
             
    txa                          // random number (in x) to acc
    sta array,y                  // save in 'array'
             
    iny                          // next array pos
    cpy #16                      // all positions in 'array' filled with numbers ?
    bne fill_loop                // no -> fill_loop
    
    rts                         // done

array: .fill 16,0               // 0...15 with zero, empty table / array
used:  .fill 16,0               // 0...15 with zero, empty table / array

// copy from origin to randomized / shuffled card_face_array 
// order is determined by the procedure above and is read from 'array'
copy:
    lda #<card_face_origin      // low byte from card source
    sta temp1                   // store in temp1
    lda #>card_face_origin      // high byte from card source
    sta temp2                   // store in temp2
 
    lda #<card_face_array       // low byte card destination
    sta temp3                   // store in temp3
    lda #>card_face_array       // high byte card destination
    sta temp4                   // store in temp 4
    
    ldy #0                      // y to zero
    ldx #0                      // acc to zero

// transfer cards to 'card_face_array', order is determined by 'array'
// outer loop is the whole entry '.word VDCRAM2 +  128,   1'
// every entry has 4 bytes hb and lb screen addr + card value (which is technically 1 byte)
// screen address of a card is origin + value from 'array' * 4 
out_loop:
    lda array,x                 // load position from 'array'
    asl                         // *2
    asl                         // *2 for 4 bytes 
    // add 8 bit to 16 bit
    clc                         // clear carry
    adc temp1                   // add to src low (temp1),
    sta temp1                   // store in source low (temp1)
    lda #0                      // 
    adc temp2                   // add to src high (temp2)
    sta temp2                   // store in scr high (temp2)
// inner loop if for the 4 bytes of every entry
inner_loop:
    lda (temp1), y              // load byte from src 
    sta (temp3), y              // write byte to dest
    iny                         // next byte
    cpy #4                      // 4 bytes written ?
    bne inner_loop              // no? -> inner_loop
    ldy #0                      // reset y to zero after 4 bytes
// increase counter for outer loop
// 'reset' temp1 (src lb) temp2 (src hb) to start values
inc_out_loop:
    // add 8 bit to 16 bit
    lda #4                      // load 4
    clc                         // clear carry
    adc temp3                   // add to dest low
    sta temp3                   // store in dest low
    lda #0                      //
    adc temp4                   // add to dest high
    sta temp4                   // store in dest high
    lda #<card_face_origin      // load lb of src origin (again), it will be increased in out_loop
    sta temp1                   // store lb of src in temp1
    lda #>card_face_origin      // load hb of src origin
    sta temp2                   // store in src high (temp)
    inx                         // increment x
    cpx #16                     // end of 'array'?
    bne out_loop                // no? -> out_loop
    rts

card_face_array: .fill 64,0     // empty card face array

/* show the cards ===================================================================== */

// vdc block copy
// values from ShowCard macro
// display_card is called from ShowCard macro
display_card:
    ldy #0                      // set y to zero
    
    lda dst_low                 // load dest screen pos low byte
    sta temp1                   // store in temp1
    lda dst_high                // load dest screen pos high byte
    sta temp2                   // store in temp2

    lda src_low                 // load source low byte
    sta temp3                   // store in temp3
    lda src_high                // load source high byte
    sta temp4                   // store in temp4
    
    ldx #24                     // reg 24 VDC
    jsr VDCREAD                 // read byte
    ora #%10000000              // set bit for block copy
    ldx #24                     // reg 24 VDC
    jsr VDCWRITE                // write byte to register

// display cards loop
!loop:
    ldx #18                     // reg 18 VDC screen pos high byte
    lda temp2                   // load dest screen pos high byte
    jsr VDCWRITE                // write reg
    ldx #19                     // reg 19 VDC screen pos low byte
    lda temp1                   // load dest screen pos low byte
    jsr VDCWRITE                // write reg

    ldx #32                     // reg 32 VDC src high byte
    lda temp4                   // load src high byte
    jsr VDCWRITE                // write reg
    ldx #33                     // reg 33 VDC src low byte
    lda temp3                   // load src low byte
    jsr VDCWRITE                // write reg

    ldx #30                     // reg 30 VDC start block transfer
    lda #8                      // size of block
    jsr VDCWRITE                // write reg

    // add 8 bit to 16 bit
    clc                         // clear carry
    lda temp1                   // load dest screen pos low byte start
    adc #80                     // add 80; end position (end of line)
    sta temp1                   // store end pos in temp 1
    lda temp2                   // load dest screen pos high byte start
    adc #0                      // do not clc and add zero
    sta temp2                   // store end pos in temp 2
    
    // add 8 bit to 16 bit
    clc                         // clear carry
    lda temp3                   // load src low byte
    adc #8                      // add 8 (8x8 char card size)
    sta temp3                   // store end pos in temp3
    lda temp4                   // load src high byte
    adc #0                      // do not clc and add zero
    sta temp4                   //  store end pos in tem4

    iny                         // increment y
    cpy #8                      // is it 8 already?
    bne !loop-                  // no? -> loop

/* game logic ========================================================================= */

// match counter, after 2 cards the card values will be added together
// if it is 255 it is a match
match_related:    
    inc match_cnt               // increment match counter
    lda match_cnt               // load match counter
    cmp #1                      // if 1: face of card 1 was shown
    beq store_cord_1            // -> store pos and card value
    lda match_cnt               // load match counter
    cmp #2                      // if 2: face of card 2 was shown
    beq store_cord_2            // -> store pos and card value

// label after return from store pos and card value of card 2
return_from_store_cord_2:   
    lda value_1                 // load card value 1
    cmp value_2                 // compare with card 2 value
    beq jsr_card_reset          // equal? selected the same card two times -> card_reset
    clc                         // clear carry
    adc value_2                 // add card value 2 to card value 1
    cmp #255                    // is it 255?
    beq card_match              // yes? it's a match -> card_match
    lda score                   // no match, load score
    sec                         // set carry
    sbc #5                      // -5 from score for wrong cards
    sta score                   // store new score
    bmi set_score_to_zero       // score should not become negative -> set_core_to_zero
    jmp jsr_card_reset          // -> jump to label for resetting cards (show back again) 
set_score_to_zero:              // if score <0, set to 0
    lda #0                      // load 0
    sta score                   // store 0 in score
jsr_card_reset:                 
    jsr card_reset              // -> rest cards (show back again)
    
return_from_card_match:         // return from card match
    lda #0                      // load 0
    sta match_cnt               // reset match counter, set to 0 (from 2)
    sta match                   // reset match, set to 0 (from 255)
    rts                         // return

// store pos and card value of first card
store_cord_1:                   
    lda dst_low                 // load low byte of card dst (pos)
    sta dst_low_crd1            // store low byte in dst_low_crd1 
    lda dst_high                // load high byte of card dst (pos)
    sta dst_high_crd1           // store high byte in dst_high_crd1
    lda match                   // load card value (ShowCard macro)
    sta value_1                 // store in value_1
    rts                         // return

// store pos and card value of second card
store_cord_2:
    lda dst_low                 // load low byte of card dst (pos)
    sta dst_low_crd2            // store low byte in dst_low_crd2 
    lda dst_high                // load high byte of card dst (pos)
    sta dst_high_crd2           // store high byte in dst_high_crd2
    lda match                   // load card value (ShowCard macro)
    sta value_2                 // store in value_2
    jmp return_from_store_cord_2 //return 

// two cards matched, sum of card values is 255    
// +25 for score
// remove matched cards from screen
card_match:
    jsr play_match_snd          // -> play tune in case of a match
    lda score                   // load score
    clc                         // clear carry
    adc #25                     // +25 points for a match
    sta score                   // store new score
    WaitSeconds(ts,t10)         // wait some time macro

    lda dst_low_crd1            // load low byte of card 1 dst (pos) 
    sta dst_low                 // store in card pos low byte
    lda dst_high_crd1           // load high byte of card 1 dst (pos) 
    sta dst_high                // store in card pos high byte
    ClearChar()                 // delete the char below the card (1,2..Q,W...) macro
    GetSpecialCardFace(1)       // show empty card black screen (macro)
    jsr reset_card              // -> rest card (show empty area)

    lda dst_low_crd2            // load low byte of card 2 dst (pos) 
    sta dst_low                 // store in card pos low byte
    lda dst_high_crd2           // load high byte of card 2 dst (pos) 
    sta dst_high                // store in card pos high byte
    ClearChar()                 // delete the char below the card (1,2..Q,W...) macro
    GetSpecialCardFace(1)       // show empty card black screen card macro
    jsr reset_card              // -> rest card (show empty area)
    jmp return_from_card_match  // -> return from match

// reset cards
// show back of the cards again in case there was no match    
card_reset:
    WaitSeconds(ts,t10)         // wait some time before showing the back side again
    lda dst_low_crd1            // load low byte of card 1 dst (pos) 
    sta dst_low                 // store in card pos low byte
    lda dst_high_crd1           // load high byte of card 1 dst (pos) 
    sta dst_high                // store in card pos high byte
    GetSpecialCardFace(0)       // show back side of the card (macro)
    jsr reset_card              // -> finally do it, use block copy

    lda dst_low_crd2            // load low byte of card 2 dst (pos) 
    sta dst_low                 // store in card pos low byte
    lda dst_high_crd2           // load high byte of card 2 dst (pos) 
    sta dst_high                // store in card pos high byte
    GetSpecialCardFace(0)       // show back side of the card (macro)
    jsr reset_card              // -> finally do it, use block copy
    rts                         // return

/* reset cards ======================================================================== */

// reset cards
// block copy
// show either back side (no match)
// or remove the cards (match)
// coordinates and faces come from macro
// same as above
// bcse of the combination with the game logic 
// I had no idea how I could reuse the above routine again
reset_card:                     
    ldy #0                      
    ldx #24                     
    jsr VDCREAD                 
    ora #%10000000              
    ldx #24                     
    jsr VDCWRITE                

!loop:
    ldx #18
    lda dst_high
    jsr VDCWRITE
    ldx #19
    lda dst_low
    jsr VDCWRITE

    ldx #32
    lda src_high
    jsr VDCWRITE
    ldx #33
    lda src_low
    jsr VDCWRITE

    ldx #30
    lda #8
    jsr VDCWRITE

    clc
    lda dst_low
    adc #80
    sta dst_low
    lda dst_high
    adc #0
    sta dst_high

    clc
    lda src_low
    adc #8
    sta src_low
    lda src_high
    adc #0
    sta src_high

    iny
    cpy #8
    bne !loop-
    rts

/* empty screen check================================================================== */

// check if there are no more cards on the screen
// just check (via macro) for $20 on the card positions 
// if this is true on all positions -> You Win! screen
check_no_cards:
    .for (var i=0; i<16; i++) { // 16 positions (0 is not used)
        GetCardPos(i)           // get positions of the cards macro
        CardStillInGame()       // is the card still on the screen?
        beq !next+              // yes
        rts                     // -> go back
    !next:                      // no cars on the screen
    }   
    jsr show_win                // -> show You Win! screen
    rts                         // return

/* You Win! Screen===================================================================== */

show_win:
    // change vdc ram to preloaded help screen location
    // show the You Win! screen
    ldx #12                     // register of screen addr high byte 
    lda #>VDCRAM3               // load VDC high byte of help screen
    sta $0A2E                   // screen mem starting page pointer
    jsr VDCWRITE                // kernal to write to VDC
    ldx #13                     // register of screen addr low byte
    lda #<VDCRAM3               // load VDC low byte
    jsr VDCWRITE                // kernal to write to VDC
    JiffyTime(60)               // wait some time macro (flashing effect)

    // show empty screen (flashing effect)
    ldx #12                     // register of screen addr high byte 
    lda #>VDCRAM                // load VDC high byte of help screen
    sta $0A2E                   // screen mem starting page pointer
    jsr VDCWRITE                // kernal to write to VDC
    ldx #13                     // register of screen addr low byte
    lda #<VDCRAM                // load VDC low byte
    jsr VDCWRITE                // kernal to write to VDC

    JiffyTime(60)               // wait some time macro (flashing effect)
    rts                         //return
      
/* display score ====================================================================== */
    
// display decimals 0 to 255
decout:
    lda score
    sta param                       // store value
    // 100 digit     
    ldx #$00                        // x counts how many times 100 can be subtracted   
    lda param                       // load value
    sec                             // set carry flag (for sbc)
decout_hund_loop:    
    sbc #100                        // subtract 100
    bcc decout_hund_done            // if result < 0 branch to done -> decout_hund_done
    sta param                       // save remaining value
    inx                             // increment hundreds counter
    jmp decout_hund_loop            // repeat

decout_hund_done:
    txa                             // transfer count to acc (0, 1, 2)
    ora #$30                        // convert to num chars ('0', '1', '2')
    cmp #$30                        // is it a leading zero?
    bne !write_num+                 // -> write_num (print number)
    lda #$20                        // load ' '
    PrintRegACharAt(7,24,VDCRAM)    // macro: display acc content at x,y (' ')
    PrintRegACharAt(7,24,VDCRAM3)   // also shot it at You Win!
    ldy #$11                        // remember ' ' was printed (for no leading 0)
!write_num:
    PrintRegACharAt(7,24,VDCRAM)    // macro: display acc content at x,y (hundreds) 
    PrintRegACharAt(7,24,VDCRAM3)   // also shot it at You Win!

    // 10 digit
    ldx #$00                        // reset x for 10 digits
    lda param                       // load remaining value (0 to 99) 
    sec                             // set carry flag (for sbc) 
decout_tens_loop:    
    sbc #10                         // subtract 10
    bcc decout_tens_done            // if result < 0 branch to done -> decout_tens_done
    sta param                       // save remaining value
    inx                             // increment tens counter
    jmp decout_tens_loop            // repeat

decout_tens_done:
    txa                             // transfer count to acc (0 to 9)
    ora #$30                        // convert to num chars ('0' to '9')
    cmp #$30                        // is it a leading zero?
    bne !write_num+                 // -> write_num (print number) 
    cpy #$11                        // was there a leading zero from the hundreds?
    bne !write_num+                 // -> write_num (print number) 
    lda #$20                        // load ' '
    ldy #$0                         // set y reg to zero (reset remember bit)
    PrintRegACharAt(8,24,VDCRAM)    // macro: display acc content at x,y (' ') 
    PrintRegACharAt(8,24,VDCRAM3)   // also shot it at You Win!
!write_num:
    PrintRegACharAt(8,24,VDCRAM)    // macro: display acc content at x,y (tens)
    PrintRegACharAt(8,24,VDCRAM3)   // also shot it at You Win!
    
    // 1 digit
    lda param                       // load remaining value (0 to 9) 
    ora #$30                        // convert to num chars ('0' to '9')
    PrintRegACharAt(9,24,VDCRAM)    // macro: display acc content at x,y (ones)
    PrintRegACharAt(9,24,VDCRAM3)   // also shot it at You Win!
    rts                             // return

/* play sound ========================================================================= */
// very simple 4 freq sound player
// Mapping the Commodore 128

// freqs to play
freqs:  .word $2200, $3300, $4400, $5500

// play in case of a match            
// all for voice 1
play_match_snd:
    // prepare
    lda #%10001111                  // volume and turn off voice 3
    sta $d418                       // store in volume / mod reg
    lda #$00                        // load 0 pulse width low byte
    sta $d402                       // store in pulse width low reg
    lda #$08                        // load $08 pulse width high byte
    sta $d403                       //  store in pulse width low reg

    lda #%00010000                  // load %00010000   
    sta $d405                       // store in attack / decay reg voice 1
    lda #%00010000                  // load %00010000 
    sta $d406                       // store in sustain / release reg voice 1
    ldx #$0                         // set counter to zero

play_loop:
    // play
    lda freqs, x                    // load freq 1 low byte
    sta $d400                       // store in freq low byte reg voice 1        
    inx                             // increment x
    lda freqs, x                    // load freq 1 high byte
    sta $d401                       // store in freq low byte reg voice 1
    inx                             // increment x
    
    lda #%01000001                  // pulse and gate on
    sta $d404                       // store in control reg voice 1
    WaitSeconds(0,2)                // WaitSeconds macro, waits 2*1/10 s
    
    lda #%01000000                  // gate off
    sta $d404                       // store in control reg voice 1
    cpx #8                          // completed 8 Bytes ?
    bne play_loop                   // no? -> play_loop
    
    lda #%10000000                  // volume off and voice 3
    sta $d418                       // store in volume / mod reg
    rts                             // return
    

/* macros ============================================================================= */ 

// https://fightingcomputers.nl/Projects/Commodore-128/Commodore-128-assembly---Part-1
// https://github.com/wiebow/examples.c128
.macro BasicUpstart128(address) {   //
    .pc = $1c01 "C128 Basic"        //
    .word upstartEnd                // link address  
    .word 10                        // line num  
    .byte $9e                       // sys  
    .text toIntString(address)      //
    .byte 0  
upstartEnd:  
    .word 0                         // empty link signals the end of the program  
    .pc = $1c0e "Basic End" 
}  

// get the position of the card
// to destination on screen
.macro GetCardPos(n){
    lda card_pos_array + n*2        // get low byte from word in array
    sta dst_low                     // store it in dst low
    lda card_pos_array + n*2 + 1    // get high byte from word in array
    sta dst_high                    // store it in dst high
}

// get the card face and value
// from source in ram
.macro GetCardFace(n){
    lda card_face_array + n*4       // get low byte from word in array
    sta src_low                     // store it in src low
    lda card_face_array + n*4 + 1   // get high byte from word in array
    sta src_high                    // store it in src high
    lda card_face_array + n*4 + 2   // get card value, low byte only
    sta match                       // store it in match
}

// get special card faces like the back side and empty (not visible) cards
// from source in ram
.macro GetSpecialCardFace(n){
    lda special_card_face_array + n*2       // get low byte from word in array
    sta src_low                             // store it in src low
    lda special_card_face_array + n*2 + 1   // get high byte from word in array
    sta src_high                            // store it in src high
}

// check if the card is still visible
// goto pos on screen and read value and compare with '$20'
// check in destination
.macro CardStillInGame(){
    ldx #18                     // register of screen addr high byte 
    lda dst_high                // load dst high byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #19                     // register of screen addr low byte 
    lda dst_low                 // load dst low byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #31                     // data register of VDC
    jsr VDCREAD                 // kernal to read from VDC
    cmp #$20                    // compare with 'space' / empty
}

// show a specific card with a specific face on a specific position
.macro ShowCard(pos, face){
    GetCardPos(pos)             // get the position of the card
    CardStillInGame()           // check if the card is still visible (still there)
    beq !return+                // if not visible -> resturn
    GetCardFace(face)           // otherwise load the face of the card
    jsr display_card            // display the card
!return:
    rts
}

// print a char at a specific position on a specific screen
// x,y row and column; VDC screen ram address
.macro PrintRegACharAt(x,y,a) {
    pha                         // push acc
    .var screen_addr = y*80 + x + a // calc screen pos as 16 bit address
    ldx #18                     // register of screen addr high byte 
    lda #>screen_addr           // load high byte
    jsr VDCWRITE                // kernal to write to VDC
    ldx #19                     // register of screen addr low byte 
    lda #<screen_addr           // load low byte
    jsr VDCWRITE                // kernal to write to VDC
    pla                         // pull acc
    ldx #31                     // data register of VDC
    jsr VDCWRITE                // kernal to write to VDC
}

// clear char below card
.macro ClearChar(){
    ldx #19                     // register of screen addr low byte 
    clc                         // clear carry
    lda dst_low                 // load dest low byte
    adc #211                    // pos of key char below card 1 2 3 ... Q W (dst_low + 211)
    jsr VDCWRITE                // kernal to write to VDC
    ldx #18                     // register of screen addr high byte 
    lda dst_high                // load dest high byte
    adc #2                      // add 2
    jsr VDCWRITE                // kernal to write to VDC
    lda #$20                    // load 'space' char / empty char
    ldx #31                     // data register of VDC
    jsr VDCWRITE                // kernal to write to VDC
}

// simple timer for You Win! screen
.macro JiffyTime(n) {
    pha                         // push acc to stack
    lda #0                      // reset timer
    sta $A2                     // store in 1/60 s reg
!wait:
    lda $A2                     // load 1/60 s reg
    cmp #n                      // compare with target time
    bne !wait-                  // not yet ? -> back to wait!
    pla                         // pull acc from stack
}

// wait seconds + 1/10 seconds
// Mapping the Commodore 128
// Time-of-day clock
.macro WaitSeconds(s1,s10) {
    sei                         // interrupts off (no keyboard input during wait)
    pha                         // push acc to stack
    lda #0                      // load 0
    sta $dc09                   // write 0 to sec reg
    sta $dc08                   // start by writing 0 to 1/10 sec reg
!wait:            
    lda $dc09                   // read sec reg
    cmp #s1                     // compare with target time in seconds
    bne !wait-                  // not yet ? -> back to wait!
!wait:                
    lda $dc08                   // read 1/10 sec reg
    cmp #s10                    // compare with target time in seconds
    bne !wait-                  // not yet ? -> back to wait!
    pla                         // pull acc from stack
    cli                         // interrupts on 
}

/* data =============================================================================== */

// screen character data
// https://petscii.krissz.hu
*=CHR_DATA "Screen character data"
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20
    .byte $20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20
    .byte $20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20
    .byte $20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20
    .byte $20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20
    .byte $20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20
    .byte $20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20
    .byte $20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$31,$20,$20,$20,$20,$20,$20,$20,$20,$20,$32,$20,$20,$20,$20,$20,$20,$20,$20,$20,$33,$20,$20,$20,$20,$20,$20,$20,$20,$20,$34,$20,$20,$20,$20,$20,$20,$20,$20,$20,$35,$20,$20,$20,$20,$20,$20,$20,$20,$20,$36,$20,$20,$20,$20,$20,$20,$20,$20,$20,$37,$20,$20,$20,$20,$20,$20,$20,$20,$20,$38,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20
    .byte $20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20
    .byte $20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20
    .byte $20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20
    .byte $20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20,$20,$CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE,$20
    .byte $20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20,$20,$A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0,$20
    .byte $20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20,$20,$A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0,$20
    .byte $20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20,$20,$CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$11,$20,$20,$20,$20,$20,$20,$20,$20,$20,$17,$20,$20,$20,$20,$20,$20,$20,$20,$20,$05,$20,$20,$20,$20,$20,$20,$20,$20,$20,$12,$20,$20,$20,$20,$20,$20,$20,$20,$20,$14,$20,$20,$20,$20,$20,$20,$20,$20,$20,$19,$20,$20,$20,$20,$20,$20,$20,$20,$20,$15,$20,$20,$20,$20,$20,$20,$20,$20,$20,$09,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$13,$03,$0F,$12,$05,$3A,$20,$20,$20,$20,$28,$0D,$01,$18,$20,$32,$30,$30,$29,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$05,$28,$18,$29,$09,$14,$20

*=CHR_DAT2  "Screen character data 2"
    // back
    .byte $CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE
    .byte $A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0
    .byte $A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0
    .byte $CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD
    .byte $CD,$A0,$A0,$CE,$CD,$A0,$A0,$CE
    .byte $A0,$CD,$CE,$A0,$A0,$CD,$CE,$A0
    .byte $A0,$CE,$CD,$A0,$A0,$CE,$CD,$A0
    .byte $CE,$A0,$A0,$CD,$CE,$A0,$A0,$CD
    // empty (black, blank)
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20
    // Q1
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $8C,$84,$81,$A0,$A3,$B2,$B2,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $93,$85,$83,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $81,$84,$83,$A0,$A3,$B2,$B2,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A1
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$D5,$DB,$C3,$A0,$A0,$A0,$A0
    .byte $A0,$CA,$DB,$C9,$B2,$84,$A0,$A0
    .byte $A0,$C3,$DB,$CB,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    // Q2
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $B1,$B0,$B0,$B0,$B0,$B0,$B0,$B1
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A2
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$D5,$DB,$C3,$A0,$A0,$A0,$A0
    .byte $A0,$CA,$DB,$C9,$B8,$B1,$A0,$A0
    .byte $A0,$C3,$DB,$CB,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    // Q3
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $90,$8F,$8B,$85,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $B5,$B3,$B2,$B8,$B0,$AC,$B0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A3
    .byte $4F,$77,$77,$77,$77,$77,$77,$50
    .byte $65,$20,$20,$20,$20,$20,$20,$67
    .byte $65,$20,$A0,$A0,$A0,$A0,$20,$67
    .byte $65,$20,$A0,$A0,$A0,$A0,$20,$67
    .byte $65,$20,$A0,$A0,$A0,$A0,$20,$67
    .byte $65,$20,$A0,$A0,$A0,$A0,$20,$67
    .byte $65,$20,$20,$20,$20,$20,$20,$67
    .byte $4C,$6F,$6F,$6F,$6F,$6F,$6F,$7A
    // Q4
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $B1,$B0,$B0,$B1,$B0,$B0,$B1,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$98,$8F,$92,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $B1,$B0,$B0,$B1,$B0,$B0,$B1,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A4
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$D5,$C3,$C9,$A0
    .byte $A0,$A0,$A0,$A0,$DD,$AF,$DD,$A0
    .byte $A0,$A0,$A0,$A0,$DD,$AF,$DD,$A0
    .byte $A0,$A0,$9A,$85,$92,$C3,$CB,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // Q5
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$90,$92,$89,$8E,$94,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A5
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$69,$20,$20,$5F,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$20,$A0,$A0
    .byte $A0,$A0,$A0,$69,$20,$E9,$A0,$A0
    .byte $A0,$A0,$A0,$20,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$20,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    // Q6
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$C2,$A0,$AE,$C2,$A0,$A0,$A0
    .byte $A0,$EB,$C9,$EE,$C2,$A0,$A0,$A0
    .byte $A0,$ED,$CB,$F1,$CA,$C3,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$88,$85,$92,$84,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A6
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$C3,$F2,$C3,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$DD,$F0,$C3,$F0,$C9,$A0
    .byte $A0,$A0,$C2,$EB,$C3,$C2,$C2,$A0
    .byte $A0,$A0,$C2,$ED,$C3,$ED,$CB,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // Q7
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$C2,$A0,$A0,$A0,$C2,$A0,$A0
    .byte $A0,$EB,$C9,$D5,$C9,$EB,$C9,$A0
    .byte $A0,$ED,$CB,$CA,$CB,$ED,$CB,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$99,$81,$8E,$8E,$85,$93,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A7
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$D5,$C0,$AE,$F0,$C9,$A0,$A0
    .byte $A0,$CA,$C9,$C2,$C2,$C2,$A0,$A0
    .byte $A0,$C0,$CB,$F1,$ED,$CB,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // Q8 ###
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $90,$8F,$8B,$85,$A0,$A0,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $B1,$B0,$B2,$B4,$AC,$B1,$A0,$A0
    .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
    .byte $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
    // A8
    .byte $4F,$77,$77,$77,$77,$77,$77,$50
    .byte $74,$01,$20,$20,$20,$20,$20,$67
    .byte $74,$20,$20,$20,$20,$20,$20,$67
    .byte $74,$20,$20,$20,$20,$20,$20,$67
    .byte $74,$20,$20,$20,$20,$20,$20,$67
    .byte $74,$20,$20,$20,$20,$20,$20,$67
    .byte $74,$20,$20,$20,$20,$20,$20,$67
    .byte $4C,$6F,$6F,$6F,$6F,$6F,$6F,$7A
    
*=CHR_DAT3 "You Win! screen character data"
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$A0,$A0,$A0,$66,$66,$66,$66,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$20,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20
    .byte $20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$A0,$A0,$A0,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20
    .byte $20,$20,$66,$66,$66,$20,$20,$66,$A0,$A0,$A0,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$66,$A0,$A0,$A0,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$66,$66,$66,$66,$20,$20,$20,$20,$20,$20,$66,$66,$66,$66,$66,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$20,$20,$20
    .byte $20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$66,$A0,$A0,$A0,$20,$66,$A0,$A0,$A0,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$A0,$A0,$A0,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$66,$66,$66,$A0,$A0,$A0,$A0,$A0,$66,$A0,$A0,$A0,$A0,$A0,$66,$20,$20,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$A0,$A0,$A0,$20,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$20,$20,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$66,$66,$A0,$A0,$A0,$20,$20,$20
    .byte $20,$20,$66,$66,$66,$20,$20,$66,$A0,$A0,$A0,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$A0,$A0,$A0,$20,$66,$66,$A0,$A0,$A0,$20,$20,$20,$20,$20,$20,$A0,$A0,$A0,$A0,$A0,$20,$A0,$A0,$A0,$A0,$A0,$20,$20,$66,$66,$A0,$A0,$A0,$A0,$A0,$20,$20,$20,$66,$66,$66,$20,$20,$66,$A0,$A0,$A0,$20,$66,$66,$66,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$66,$66,$66,$66,$66,$20,$66,$66,$66,$66,$66,$20,$20,$20,$20,$66,$66,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20,$66,$66,$66,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    .byte $20,$13,$03,$0F,$12,$05,$3A,$20,$20,$20,$20,$28,$0D,$01,$18,$20,$32,$30,$30,$29,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$05,$28,$18,$29,$09,$14,$20
