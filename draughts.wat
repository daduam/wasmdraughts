(module
  (import "events" "piecemoved" (func $notify_piecemoved (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32)))
  (import "events" "piececrowned" (func $notify_piececrowned (param $pieceX i32) (param $pieceY i32)))

  (global $BLACK i32 (i32.const 1))
  (global $WHITE i32 (i32.const 2))
  (global $CROWN i32 (i32.const 4))

  (global $currentTurn (mut i32) (i32.const 0))

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
    local.get $value
    local.get $low
    i32.ge_s
    local.get $value
    local.get $high
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

  ;; $getTurnOwner gets the current turn owner (black or white)
  (func $getTurnOwner (result i32)
    global.get $currentTurn
  )

  ;; $setTurnOwner sets the turn owner
  (func $setTurnOwner (param $piece i32)
    local.get $piece
    global.set $currentTurn
  )

  ;; $toggleTurnOwner switches turn owner to other player
  (func $toggleTurnOwner
    call $getTurnOwner
    i32.const 1
    i32.eq
    if
      i32.const 2
      call $setTurnOwner
    else
      i32.const 1
      call $setTurnOwner
    end
  )

  ;; $isPlayersTurn determines if it is a player's turn
  (func $isPlayersTurn (param $player i32) (result i32)
    local.get $player
    call $getTurnOwner
    i32.and
    i32.const 0
    i32.gt_s
  )

  ;; Should piece get crowned?
  ;; We crown black pieces in row 0, white pieces in row 7
  (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    local.get $pieceY
    i32.const 0
    i32.eq
    local.get $piece
    call $isBlack
    i32.and
    local.get $pieceY
    i32.const 7
    i32.eq
    local.get $piece
    call $isWhite
    i32.and
    i32.or
  )

  ;; Converts a piece into a crowned piece and invokes
  ;; a host notifier
  (func $crownPiece (param $x i32) (param $y i32)
    (local $piece i32)
    local.get $x
    local.get $y
    call $getPiece
    local.set $piece

    local.get $x
    local.get $y
    local.get $piece
    call $withCrown
    call $setPiece

    local.get $x
    local.get $y
    call $notify_piececrowned
  )

  ;; Calculates distance
  (func $distance (param $x i32) (param $y i32) (result i32)
    local.get $x
    local.get $y
    i32.sub
  )

  ;; Determine if move is valid
  (func $isValidMove (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $player i32)
    (local $target i32)

    local.get $fromX
    local.get $fromY
    call $getPiece
    local.set $player

    local.get $toX
    local.get $toY
    call $getPiece
    local.set $target

    block (result i32)
      local.get $fromY
      local.get $toY
      call $validJumpDistance
      local.get $player
      call $isPlayersTurn
      local.get $target
      i32.const 0
      i32.eq ;; target must be unoccupied
      i32.and
      i32.and
    end
    if (result i32)
      i32.const 1
    else
      i32.const 0
    end
  )

  ;; Ensures travel is 1 or 2 squares
  (func $validJumpDistance (param $from i32) (param $to i32) (result i32)
    (local $d i32)

    local.get $to
    local.get $from
    i32.gt_s
    if (result i32)
      local.get $to
      local.get $from
      call $distance
    else
      local.get $from
      local.get $to
      call $distance
    end
    local.set $d

    local.get $d
    i32.const 2
    i32.le_u
  )

  ;; Exported move function to be called by the game host
  ;; returns 1 on successful move and 0 otherwise
  (func $move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    block (result i32)
      local.get $fromX
      local.get $fromY
      local.get $toX
      local.get $toY
      call $isValidMove
    end 
    if (result i32)
      local.get $fromX
      local.get $fromY
      local.get $toX
      local.get $toY
      call $do_move
    else
      i32.const 0
    end
  )

  ;; Internal move function, performs actual move post-validation of target
  ;; Currently not handled:
  ;; - removing opponent piece during jump
  ;; - detecting win condition
  (func $do_move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
    (local $curpiece i32)
    local.get $fromX
    local.get $fromY
    call $getPiece
    local.set $curpiece

    call $toggleTurnOwner

    local.get $toX
    local.get $toY
    local.get $curpiece
    call $setPiece

    local.get $fromX
    local.get $fromY
    i32.const 0
    call $setPiece

    local.get $toY
    local.get $curpiece
    call $shouldCrown
    if
      local.get $toX
      local.get $toY
      call $crownPiece
    end

    local.get $fromX
    local.get $fromY
    local.get $toX
    local.get $toY
    call $notify_piecemoved

    i32.const 1
  )

  ;; Manually place each piece on the board to initialize the game
  (func $initBoard
    ;; place white pieces at the top of the board
    (call $setPiece (i32.const 1) (i32.const 0) (global.get $WHITE))
    (call $setPiece (i32.const 3) (i32.const 0) (global.get $WHITE))
    (call $setPiece (i32.const 5) (i32.const 0) (global.get $WHITE))
    (call $setPiece (i32.const 7) (i32.const 0) (global.get $WHITE))

    (call $setPiece (i32.const 0) (i32.const 1) (global.get $WHITE))
    (call $setPiece (i32.const 2) (i32.const 1) (global.get $WHITE))
    (call $setPiece (i32.const 4) (i32.const 1) (global.get $WHITE))
    (call $setPiece (i32.const 6) (i32.const 1) (global.get $WHITE))

    (call $setPiece (i32.const 1) (i32.const 2) (global.get $WHITE))
    (call $setPiece (i32.const 3) (i32.const 2) (global.get $WHITE))
    (call $setPiece (i32.const 5) (i32.const 2) (global.get $WHITE))
    (call $setPiece (i32.const 7) (i32.const 2) (global.get $WHITE))

    ;; place black pieces at the bottom of the board
    (call $setPiece (i32.const 0) (i32.const 5) (global.get $BLACK))
    (call $setPiece (i32.const 2) (i32.const 5) (global.get $BLACK))
    (call $setPiece (i32.const 4) (i32.const 5) (global.get $BLACK))
    (call $setPiece (i32.const 6) (i32.const 5) (global.get $BLACK))
    
    (call $setPiece (i32.const 1) (i32.const 6) (global.get $BLACK))
    (call $setPiece (i32.const 3) (i32.const 6) (global.get $BLACK))
    (call $setPiece (i32.const 5) (i32.const 6) (global.get $BLACK))
    (call $setPiece (i32.const 7) (i32.const 6) (global.get $BLACK))

    (call $setPiece (i32.const 0) (i32.const 7) (global.get $BLACK))
    (call $setPiece (i32.const 2) (i32.const 7) (global.get $BLACK))
    (call $setPiece (i32.const 4) (i32.const 7) (global.get $BLACK))
    (call $setPiece (i32.const 6) (i32.const 7) (global.get $BLACK))

    (call $setTurnOwner (i32.const 1)) ;; black goes first
  )

  (export "getPiece" (func $getPiece))
  (export "isCrowned" (func $isCrowned))
  (export "initBoard" (func $initBoard))
  (export "getTurnOwner" (func $getTurnOwner))
  (export "move" (func $move))
  (export "memory" (memory $mem))
)
