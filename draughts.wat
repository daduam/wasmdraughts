(module
  (global $BLACK i32 (i32.const 1))
  (global $WHITE i32 (i32.const 2))
  (global $CROWN i32 (i32.const 4))

  (memory $mem 1)

  (func $indexForPosition (param $x i32) (param $y i32) (result i32)
    local.get $y
    i32.const 8
    i32.mul
    local.get $x
    i32.add
  )

  ;; offset = 4 * (x + y * 8)
  (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
    local.get $x
    local.get $y
    call $indexForPosition
    i32.const 4
    i32.mul
  )

  ;; Determin if a piece has been crowned
  (func $isCrowned (param $piece i32) (result i32)
    local.get $piece
    global.get $CROWN
    i32.and
    global.get $CROWN
    i32.eq
  )
  
  ;; Determine if a piece is white
  (func $isWhite (param $piece i32) (result i32)
    local.get $piece
    global.get $WHITE
    i32.and
    global.get $WHITE
    i32.eq
  )

  ;; Determine if a piece is black
  (func $isBlack (param $piece i32) (result i32)
    local.get $piece
    global.get $BLACK
    i32.and
    global.get $BLACK
    i32.eq
  )

  ;; Adds a crown to a given piec (no mutation)
  (func $withCrown (param $piece i32) (result i32)
    local.get $piece
    global.get $CROWN
    i32.or
  )

  ;; Removes a crown from a given piece (no mutation)
  (func $withoutCrown (param $piece i32) (result i32)
    local.get $piece
    i32.const 3
    i32.or
  )

  ;; $setPiece sets a piece on the board
  (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    local.get $x
    local.get $y
    call $offsetForPosition
    local.get $piece
    i32.store
  )

  ;; $inRange detects if values are within range (low and high inclusive)
  (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
    local.get $low
    local.get $value
    i32.ge_s
    local.get $high
    local.get $value
    i32.le_s
    i32.and
  )

  ;; $getPiece Gets a piece from the board. Out of range causes a trap
  (func $getPiece (param $x i32) (param $y i32) (result i32)
    block (result i32)
      i32.const 0
      i32.const 7
      local.get $x
      call $inRange
      i32.const 0
      i32.const 7
      local.get $y
      call $inRange
      i32.and
    end
    if (result i32)
      local.get $x
      local.get $y
      call $offsetForPosition
      i32.load
    else
      unreachable
    end
  )
)
