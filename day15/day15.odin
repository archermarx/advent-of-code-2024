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


Vec2 :: distinct [2]int

Tile :: enum {
	Floor,
	Box,
	Wall,
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
	padding := "  "

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
			if robot_pos.x == x && robot_pos.y == y {
				fmt.sbprintf(&buf, "%s@%s%s", BRED, padding, COFF)
				continue
			}
			switch tile {
			case .Floor:
				fmt.sbprintf(&buf, "%s.%s%s", BLK, pad, COFF)
			case .Wall:
				fmt.sbprintf(&buf, "%s#%s%s", BMAG, pad, COFF)
			case .Box:
				fmt.sbprintf(&buf, "%sO%s%s", BBLU, pad, COFF)
			}
		}
		fmt.sbprintln(&buf, '│')
	}
	print_header(&buf, width, '╰', '╯', len(padding))
	str := strings.to_string(buf)
	fmt.print(str)
}

predict_moves :: proc(input: string, allocator := context.allocator) {
	_input := input

	tiles := make([dynamic][]Tile, allocator)
	commands := make([dynamic]u8, allocator)
	read_commands: bool
	robot_pos: Vec2

	y := 0
	for line in strings.split_lines_iterator(&_input) {
		if read_commands {
			for c in transmute([]u8)line {
				append(&commands, c)
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
					robot_pos = Vec2{x, y}
					row[x] = .Floor
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

	print_tiles(tiles[:], robot_pos)

}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 15!")
	predict_moves(example01)
}
