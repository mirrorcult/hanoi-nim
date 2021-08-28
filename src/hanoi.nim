let doc = """
Nim Hanoi

Usage:
  hanoi <disks> <startrod> <endrod> [-a | --auto]

Options:
  -h --help     Show this screen.
  --version     Show version.
  -a --auto     Advance moves automatically, every 10 frames.
"""

import strutils
import docopt
import sdl2
import random

randomize()

let args = docopt(doc, version = "Hanoi v1.1.0")

# e.g.
# rod number - disk numbers
# 1 - 1, 2
# 2 - 
# 3 - 3
# lower number = larger disk
type
  GameState = array[3, seq[int]]
  Colors = array[7, tuple[r: uint8, g: uint8, b: uint8, a: uint8]]
  HanoiMoves = seq[tuple[f: int, to: int]]

var
  RenderDisk = parseInt($args["<disks>"])
  RenderStartrod = parseInt($args["<startrod>"])
  RenderEndrod = parseInt($args["<endrod>"])

const
  WindowWidth = 1366
  WindowHeight = 768

  RodWidth = 40

  DiskHeight = 80

var
  RodHeight = WindowHeight * 0.75
  RodY = WindowHeight - RodHeight
  LargestDiskWidth = WindowWidth div 4

  FrameCount = 0
  Window: WindowPtr
  Renderer: RendererPtr
  evt = sdl2.defaultEvent

  Moves: HanoiMoves

const
  # i really shouldn't have to do this but nim refused to implicitly convert
  # fucking int  literal to uint8
  DiskColors: Colors = [
    (uint8(255), uint8(0), uint8(0), uint8(255)),
    (uint8(255), uint8(165), uint8(0), uint8(255)),
    (uint8(255), uint8(255), uint8(0), uint8(255)),
    (uint8(0), uint8(128), uint8(0), uint8(255)),
    (uint8(0), uint8(0), uint8(255), uint8(255)),
    (uint8(75), uint8(0), uint8(130), uint8(255)),
    (uint8(238), uint8(130), uint8(238), uint8(255))
  ]  

echo "$# $# $#".format(RenderDisk, RenderStartrod, RenderEndrod)

proc render_rods() : void =
  Renderer.setDrawColor(173, 111, 105, 255)
  for i in 1..3:
    var
      x = (WindowWidth div 4) * i - RodWidth div 2
      y = RodY 
      r: Rect = rect(
        cint(x),
        cint(y),
        cint(RodWidth),
        cint(RodHeight)
      )
    Renderer.fillRect(r)

proc render_disks(state: GameState) : void =
  for i, r in state.pairs:
    for j, d in r.pairs:
      var color = DiskColors[(d - 1) mod 7]
      # couldnt get splat to work, kiss myass
      Renderer.setDrawColor(color.r, color.g, color.b, color.a);
      var 
        y = WindowHeight - ((j + 1) * (DiskHeight))
        width = (LargestDiskWidth.float * ((RenderDisk.float + 1 - d.float) / RenderDisk.float)).int
        x = (WindowWidth div 4) * (i + 1) - width div 2
        height = DiskHeight
        r: Rect = rect(
          cint(x),
          cint(y),
          cint(width),
          cint(height)
        )
      Renderer.fillRect(r)


proc render_scene(state: GameState): void =
  Renderer.setDrawColor(0, 0, 0, 255)
  Renderer.clear();

  render_rods()
  render_disks(state)

  inc FrameCount

  Renderer.present()

proc hanoi(disk, source, dest: int) =
  if disk == RenderDisk:
    Moves.add((source, dest))
    return
  else:
    var spare = 3 - (source + dest)
    hanoi(disk + 1, source, spare)
    Moves.add((source, dest))
    hanoi(disk + 1, spare, dest)


proc construct_gamestate(disks, startrod, endrod: int): GameState =
  var state: GameState
  for i in 1..disks:
    state[startrod].add(i)
  return state

proc test_gamestate(disks, startrod, endrod: int): GameState =
  var state: GameState
  for i in 1..disks:
    state[rand(0..2)].add(i)
  return state

var
    State = construct_gamestate(RenderDisk, RenderStartrod, RenderEndrod)

proc advance_move() =
  if Moves.len == 0: return
  var (source, dest) = Moves[0]
  var a = State[source].pop()
  State[dest].add(a)
  Moves.delete(0)

proc main() =
  var
    running = true

  discard sdl2.init(INIT_EVERYTHING)
  Window = createWindow(
    title = "Hanoi",
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED,
    w = WindowWidth, 
    h = WindowHeight, 
    flags = SDL_WINDOW_SHOWN
  )

  Renderer = createRenderer(
    window = Window,
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  # fill moves
  hanoi(1, RenderStartrod, RenderEndrod)
  echo Moves

  while running:
    while pollEvent(evt):
      case evt.kind
      of QuitEvent:
        running = false
        break
      of KeyUp:
        advance_move()
      else:
        discard

    if FrameCount mod 15 == 0 and parseBool($args["--auto"]) == true:
      advance_move()
    
    render_scene(State)

main()