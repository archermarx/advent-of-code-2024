package main

import "core:fmt"
import "core:os"
import "core:strings"

example := `MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX`


Grid :: struct($T: typeid) {
	rows: [][]T,
}

create_grid :: proc(input: ^string) -> Grid(u8) {
	rows: [dynamic][]u8
	for line in strings.split_lines_iterator(input) {
		append(&rows, transmute([]u8)line)
	}
	return {rows[:]}
}

grid_dims :: proc(grid: Grid($T)) -> (int, int) {
	num_rows := len(grid.rows)
	num_cols := len(grid.rows[0])
	return num_rows, num_cols
}

matches_from_cell :: proc(grid: Grid(u8), row: int, col: int) -> int {
	num_rows, num_cols := grid_dims(grid)
	matches :: [?]string{"SAMX", "XMAS"}

	sum := 0
	for m in matches {
		if grid.rows[row][col] != m[0] do continue

		can_go_left := col >= len(m) - 1
		can_go_right := col <= (num_cols - len(m))
		can_go_down := row <= (num_rows - len(m))

		if can_go_right {
			match := true
			for i in 1 ..< len(m) {
				if grid.rows[row][col + i] != m[i] {
					match = false
					break
				}
			}
			sum += int(match)
		}

		if can_go_down && can_go_right {
			match := true
			for i in 1 ..< len(m) {
				if grid.rows[row + i][col + i] != m[i] {
					match = false
					break
				}
			}
			sum += int(match)
		}

		if can_go_down {
			match := true
			for i in 1 ..< len(m) {
				if grid.rows[row + i][col] != m[i] {
					match = false
					break
				}
			}
			sum += int(match)
		}

		if can_go_down && can_go_left {
			match := true
			for i in 1 ..< len(m) {
				if grid.rows[row + i][col - i] != m[i] {
					match = false
					break
				}
			}
			sum += int(match)
		}
	}

	return sum
}

count_matches :: proc(grid: Grid(u8)) -> int {
	num_rows, num_cols := grid_dims(grid)
	sum := 0
	for row in 0 ..< num_rows {
		for col in 0 ..< num_cols {
			sum += matches_from_cell(grid, row, col)
		}
	}
	return sum
}

cell_has_xmas :: proc(grid: Grid(u8), row: int, col: int) -> bool {
	num_rows, num_cols := grid_dims(grid)
	sum := 0

	up_left := grid.rows[row - 1][col - 1]
	up_right := grid.rows[row - 1][col + 1]
	down_left := grid.rows[row + 1][col - 1]
	down_right := grid.rows[row + 1][col + 1]

	if ((up_left == 'M' && down_right == 'S') || (up_left == 'S' && down_right == 'M')) &&
	   ((up_right == 'M' && down_left == 'S') || (up_right == 'S' && down_left == 'M')) {
		return true
	}

	return false
}

count_x_mas :: proc(grid: Grid(u8)) -> int {
	num_rows, num_cols := grid_dims(grid)
	sum := 0
	for row in 1 ..< num_rows - 1 {
		for col in 1 ..< num_cols - 1 {
			if grid.rows[row][col] != 'A' do continue
			sum += int(cell_has_xmas(grid, row, col))
		}
	}
	return sum
}

main :: proc() {
	contents, ok := os.read_entire_file_from_filename("input")
	input := string(contents)
	defer delete(contents)

	if !ok {
		fmt.eprintf("Could not read file!")
		os.exit(1)
	}

	example_grid := create_grid(&example)
	defer delete(example_grid.rows)

	input_grid := create_grid(&input)
	defer delete(input_grid.rows)

	fmt.println("Example 1: ", count_matches(example_grid), " (expected 18)")
	fmt.println("Input 1: ", count_matches(input_grid))
	fmt.println("Example 2: ", count_x_mas(example_grid), " (expected 9)")
	fmt.println("Input 2: ", count_x_mas(input_grid))
}
