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


example03 := `#######
#...#.#
#.....#
#..OO@#
#..O..#
#.....#
#######

<vv<<^^<<^^`


Vec2 :: distinct [2]int

Directions :: [256]Vec2 {
	'<' = Vec2{-1, 0},
	'>' = Vec2{1, 0},
	'^' = Vec2{0, -1},
	'v' = Vec2{0, 1},
}

BRED :: "\x1b[1;31m"
BLK :: "\x1b[0;30m"
BBLU :: "\x1b[1;34m"
BGRN :: "\x1b[1;36m"
COFF :: "\x1b[0m"

tile_color :: proc(tile: u8) -> string {
	switch (tile) {
	case '@':
		return BRED
	case 'O', '[', ']':
		return BBLU
	case '#':
		return BGRN
	case:
		return BLK
	}
}

print_tiles :: proc(tiles: [][]u8, double_width: bool) {
	buf: strings.Builder
	defer strings.builder_destroy(&buf)
	width := len(tiles[0])
	padding := "" if double_width else " "

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
			fmt.sbprintf(&buf, "%s%c%s%s", tile_color(tile), tile, pad, COFF)
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

move_if_possible :: proc(tiles: [][]u8, pos: Vec2, dir: u8) -> (move: bool, next: Vec2) {
	width, height := len(tiles[0]), len(tiles)
	dirs := Directions

	next = pos + dirs[dir]

	if !in_bounds(next, width, height) do return false, pos

	// Next position is in-bounds
	tile := tiles[next.y][next.x]

	switch (tile) {
	case '#':
		break
	case '.':
		move = true
	case 'O':
		move, _ = move_if_possible(tiles, next, dir)
	}

	if move {
		tiles[next.y][next.x], tiles[pos.y][pos.x] = tiles[pos.y][pos.x], '.'
	}

	return move, (next if move else pos)
}

predict_moves :: proc(
	input: string,
	double_width := false,
	visualize := false,
	allocator := context.allocator,
) -> int {
	_input := input

	tiles := make([dynamic][]u8, allocator)
	commands := make([dynamic]u8, allocator)
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
			for cmd in transmute([]u8)line {
				append(&commands, cmd)
			}
			continue
		}

		if len(line) == 0 {
			read_commands = true
			continue
		}


		row := make([dynamic]u8, allocator)

		for c, x in transmute([]u8)line {
			switch c {
			case '@':
				robot_pos = Vec2{x, y}
				append(&row, '@')
				if double_width do append(&row, '.')
			case 'O':
				if double_width {
					append(&row, "[]")
				} else {
					append(&row, c)
				}
			case:
				append(&row, c)
				if double_width do append(&row, c)
			}
		}

		append(&tiles, row[:])
		y += 1
	}

	if visualize do print_tiles(tiles[:], double_width)

	for cmd in commands {
		_, robot_pos = move_if_possible(tiles[:], robot_pos, cmd)
		if visualize {
			fmt.printfln("Command: %c", cmd)
			print_tiles(tiles[:], double_width)
		}
	}

	// Calculate GPS coordinates
	sum_coords := 0
	width, height := len(tiles[0]), len(tiles)
	for row, j in tiles {
		for tile, i in row {
			if tile == 'O' {
				sum_coords += i + 100 * j
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
	fmt.printfln("Example 1-1: %v (expected %v)", predict_moves(example01), 2028)
	fmt.printfln("Example 1-2: %v (expected %v)", predict_moves(example02), 10092)
	fmt.printfln("Input 1: %v", predict_moves(input))
	fmt.printfln(
		"Example 2-0: %v (expected %v)",
		predict_moves(example03, true, visualize = true),
		2028,
	)
	//fmt.printfln("Example 2-1: %v (expected %v)", predict_moves(example02, true), 9021)
}
