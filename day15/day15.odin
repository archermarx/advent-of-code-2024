package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

example01 := `########
#..O.O.#
##@.O..#
#...O..#
#.#.O..#
#...O..#
#......#
########

<^^>>>vv<v>>v<<`


example02 := `##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^`


Vec2 :: distinct [2]int

Tile :: enum {
	Floor,
	Box,
	Wall,
	Robot,
}

Dir :: enum {
	Left = 0,
	Up,
	Right,
	Down,
}

Directions :: [4]Vec2 {
	Dir.Left  = Vec2{-1, 0},
	Dir.Right = Vec2{1, 0},
	Dir.Up    = Vec2{0, -1},
	Dir.Down  = Vec2{0, 1},
}

BRED :: "\x1b[1;31m"
BLK :: "\x1b[0;30m"
BBLU :: "\x1b[1;34m"
BMAG :: "\x1b[1;36m"
COFF :: "\x1b[0m"

print_tiles :: proc(tiles: [][]Tile, robot_pos: Vec2) {
	buf: strings.Builder
	defer strings.builder_destroy(&buf)
	width := len(tiles[0])
	padding := " "

	print_header :: proc(buf: ^strings.Builder, width: int, left: rune, right: rune, pad: int) {
		fmt.sbprint(buf, left)
		for _ in 0 ..< width * (pad + 1) - pad {
			fmt.sbprint(buf, '─')
		}
		fmt.sbprintln(buf, right)
	}

	print_header(&buf, width, '╭', '╮', len(padding))
	for row, y in tiles {
		fmt.sbprint(&buf, '│')
		for tile, x in row {
			pad := padding if x < width - 1 else ""
			switch tile {
			case .Floor:
				fmt.sbprintf(&buf, "%s.%s%s", BLK, pad, COFF)
			case .Wall:
				fmt.sbprintf(&buf, "%s#%s%s", BMAG, pad, COFF)
			case .Box:
				fmt.sbprintf(&buf, "%sO%s%s", BBLU, pad, COFF)
			case .Robot:
				fmt.sbprintf(&buf, "%s@%s%s", BRED, pad, COFF)
			}
		}
		fmt.sbprintln(&buf, '│')
	}
	print_header(&buf, width, '╰', '╯', len(padding))
	str := strings.to_string(buf)
	fmt.print(str)
}

in_bounds :: proc(pos: Vec2, width: int, height: int) -> bool {
	if pos.x >= 0 && pos.y >= 0 && pos.x < width && pos.y < height {
		return true
	}
	return false
}

move_if_possible :: proc(tiles: [][]Tile, pos: Vec2, dir: Dir) -> (move: bool, next: Vec2) {
	width, height := len(tiles[0]), len(tiles)
	dirs := Directions

	next = pos + dirs[dir]

	if !in_bounds(next, width, height) do return false, pos

	// Next position is in-bounds
	tile := tiles[next.y][next.x]

	switch (tile) {
	case .Wall, .Robot:
		break
	case .Floor:
		move = true
	case .Box:
		move, _ = move_if_possible(tiles, next, dir)
	}

	if move {
		// Set grid
		tiles[next.y][next.x] = tiles[pos.y][pos.x]
		tiles[pos.y][pos.x] = .Floor
	}

	return move, (next if move else pos)
}

predict_moves :: proc(input: string, visualize := false, allocator := context.allocator) -> int {
	_input := input

	tiles := make([dynamic][]Tile, allocator)
	commands := make([dynamic]Dir, allocator)
	defer {
		for row in tiles do delete(row)
		delete(tiles)
		delete(commands)
	}
	read_commands: bool
	robot_pos: Vec2

	y := 0
	for line in strings.split_lines_iterator(&_input) {
		if read_commands {
			for c in transmute([]u8)line {
				cmd: Dir
				switch c {
				case '<':
					cmd = .Left
				case '^':
					cmd = .Up
				case '>':
					cmd = .Right
				case 'v':
					cmd = .Down
				}
				append(&commands, cmd)
			}
			continue
		}
		if len(line) == 0 {
			read_commands = true
			continue
		}

		all_wall := true
		row := make([]Tile, len(line) - 2, allocator)

		for c, x in transmute([]u8)line[1:len(line) - 1] {
			if c != '#' {
				all_wall = false
			}
			switch c {
			case '@':
				{
					robot_pos = Vec2{x, y - 1}
					row[x] = .Robot
				}
			case '#':
				row[x] = .Wall
			case '.':
				row[x] = .Floor
			case 'O':
				row[x] = .Box
			}
		}
		if all_wall {
			delete(row)
		} else {
			append(&tiles, row)
		}

		y += 1
	}

	if visualize do print_tiles(tiles[:], robot_pos)

	for cmd in commands {
		_, robot_pos = move_if_possible(tiles[:], robot_pos, cmd)
		if visualize {
			fmt.printfln("Command: %v", cmd)
			print_tiles(tiles[:], robot_pos)
		}
	}

	// Calculate GPS coordinates
	sum_coords := 0
	width, height := len(tiles[0]), len(tiles)
	for row, j in tiles {
		for tile, i in row {
			if tile == .Box {
				sum_coords += (i + 1) + 100 * (j + 1)
			}
		}
	}
	return sum_coords
}


main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 15!")
	fmt.printfln("Example 1-1: %v (expected %v)", predict_moves(example01, visualize = true), 2028)
	fmt.printfln("Example 1-2: %v (expected %v)", predict_moves(example02), 10092)
	fmt.printfln("Input 1: %v", predict_moves(input))
}
