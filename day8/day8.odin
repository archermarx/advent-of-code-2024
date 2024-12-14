package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example := `............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............`


Vec2 :: distinct [2]int

count_antinodes :: proc(input: string, count_all: bool = false) -> int {
	_input := input

	antennae := make(map[rune][dynamic]Vec2, context.temp_allocator)
	antinodes := make(map[Vec2]bool, context.temp_allocator)

	// fill grids
	num_rows := 0
	num_cols := 0
	for line in strings.split_lines_iterator(&_input) {
		num_cols = len(line)
		for c, col in line {
			if c == '.' do continue
			if !(c in antennae) {
				antennae[c] = make([dynamic]Vec2, context.temp_allocator)
			}
			pos1: Vec2 = {num_rows, col}

			// compute antinode positions
			for pos2 in antennae[c] {
				diff := (pos2 - pos1)
				if !count_all {
					antinodes[pos2 + diff] = true
					antinodes[pos1 - diff] = true
					continue
				}

				p := pos1
				for p.x < num_cols && p.x >= 0 {
					antinodes[p] = true
					p += diff
				}
				p = pos1 - diff
				for p.x < num_cols && p.x >= 0 {
					antinodes[p] = true
					p -= diff
				}
			}

			append(&antennae[c], pos1)
		}
		num_rows += 1
	}

	nodes := 0
	for pos, _ in antinodes {
		if pos.x < 0 || pos.x >= num_cols do continue
		if pos.y < 0 || pos.y >= num_rows do continue
		nodes += 1
	}

	return nodes
}


main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file_from_filename("input_day8.txt", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Example 1: ", count_antinodes(example), " (expected  14)")
	fmt.println("Input 1: ", count_antinodes(input))
	fmt.println("Example 2: ", count_antinodes(example, count_all = true), " (expected  34)")
	fmt.println("Input 2: ", count_antinodes(input, count_all = true))
}
