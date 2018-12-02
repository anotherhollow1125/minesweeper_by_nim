import random
import sequtils

type
  State = enum
    closed, opened, flaged

  Box = ref object
    kind: int
    state: State
    pos: array[2, int]

  Field = seq[seq[Box]]

let EIGHT_WAY = [[-1, -1], [0, -1], [1, -1],
                 [-1, 0], [1, 0],
                 [-1, 1], [0, 1], [1, 1]]

var
  field: Field = @[]
  width, height : int
  bomb_num : int

proc getBoxKind(i, j : int): int {. exportc .} =
  return field[i][j].kind

proc getBoxState(i, j : int): cstring {. exportc .} =
  return $field[i][j].state

proc getBoxClass(i, j : int): cstring {. exportc .} =
  var box = field[i][j]
  case box.kind
  of 1:
    return "one"
  of 2:
    return "two"
  of 3:
    return "three"
  of 4..8:
    return "many"
  else:
    return ""

proc init(w, h, b_num: int): Field {. exportc .} =
  width = w
  height = h
  bomb_num = b_num
  field = @[]
  # echo "width: " & $width
  # echo "height: " & $height
  if bomb_num >= width * height - 1: bomb_num = width * height - 1
  randomize()
  var bombs : seq[array[2, int]]
  for i in 0..<bomb_num:
    var x, y : int
    while true:
      x = rand(w-1)
      y = rand(h-1)
      if bombs.all(proc (b: array[2, int]): bool = return [x, y] != b):
        break
    bombs.add([x, y])

  for i in 0..<h:
    var line: seq[Box] = @[]
    for j in 0..<w:
      var count = 0
      block j_block:
        for b in bombs:
          if [j, i] == b:
            line.add(Box(kind: -1, state: closed, pos: [j, i]))
            # echo "add bomb at " & $b
            break j_block
          else:
            for d in EIGHT_WAY:
              if [j + d[0], i + d[1]] == b:
                count += 1
        line.add(Box(kind: count, state: closed, pos: [j, i]))
    field.add(line)

  # for line in field:
  #   echo $len(line)
    # var tmp: string = ""
    # for box in line:
    #   tmp &= "," & $box.kind
    # echo tmp

# proc open(box: Box, start: bool): bool {. exportc .} =
proc open(i, j: int; start: bool): bool {. exportc .} =
  var box = field[i][j]
  if start and (box.state == flaged):
    return true
  elif box.state == opened:
    return true
  elif box.kind == -1:
    return false

  box.state = opened
  if box.kind == 0:
    for d in EIGHT_WAY:
      var
        tx = box.pos[0] + d[0]
        ty = box.pos[1] + d[1]
      if 0 <= tx and tx < width and 0 <= ty and ty < height:
        # discard field[tx][ty].open(false)
        discard open(ty, tx, false)
  return true

proc check(): bool {. exportc .} =
  for line in field:
    for box in line:
      if box.state == closed and box.kind != -1:
        return false
  return true

# proc flag(box: Box) {. exportc .} =
proc flag(i, j: int) {. exportc .} =
  var box = field[i][j]
  if box.state == closed:
    box.state = flaged
  elif box.state == flaged:
    box.state = closed

proc gameOver() {. exportc .} =
  for line in field:
    for box in line:
      box.state = opened