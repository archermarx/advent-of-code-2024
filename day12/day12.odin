package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example01 := `AAAA
BBCD
BBCC
EEEC`


example02 := `RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE`


example03 := `AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA`


Vec2 :: distinct [2]int

Left :: Vec2{0, -1}
Down :: Vec2{1, 0}
Right :: Vec2{0, 1}
Up :: Vec2{-1, 0}
directions :: [4]Vec2{Left, Down, Right, Up}


flood_fill :: proc(
	start: Vec2,
	grid: []string,
	visited: [][]bool,
	count_sides := false,
	allocator := context.allocator,
) -> (
	area: int,
	perimeter: int,
) {

	num_rows := len(grid)
	num_cols := len(grid[0])
	queue := make([dynamic]Vec2, allocator)
	index := 0
	visited[start.x][start.y] = true

	neighbor_same: [4]bool

	// Standard breadth-first search
	// Area is just the number of nodes we visit
	// Perimeter is the number of edges that connect to nodes
	// of other colors
	append(&queue, start)
	for index < len(queue) {
		pos := queue[index]
		val := grid[pos.x][pos.y]
		area += 1

		for dir, ind in directions {
			neighbor_same[ind] = false
			nextpos := pos + dir
			if nextpos.x < 0 || nextpos.x >= num_cols || nextpos.y < 0 || nextpos.y >= num_rows {
				if !count_sides do perimeter += 1
				continue
			}

			nextval := grid[nextpos.x][nextpos.y]
			if nextval != val {
				if !count_sides do perimeter += 1
				continue
			}

			neighbor_same[ind] = true
			if visited[nextpos.x][nextpos.y] do continue

			visited[nextpos.x][nextpos.y] = true
			append(&queue, nextpos)
		}

		index += 1

		if !count_sides do continue

		// check for corners -- num corners == num sides
		// iterate over pairs of neighboring directions
		dirs := directions
		for dir1, ind1 in dirs {
			ind2: int
			if ind1 == 3 {
				ind2 = 0
			} else {
				ind2 = ind1 + 1
			}
			dir2 := dirs[ind2]
			diag := pos + dir1 + dir2

			if !(neighbor_same[ind1] || neighbor_same[ind2]) {
				// convex corner
				//   A B
				//   B *
				// Don't care what diagonal is
				perimeter += 1
				continue
			}

			diag_same: bool
			if diag.x < 0 || diag.x >= num_rows || diag.y < 0 || diag.y >= num_rows {
				diag_same = false
			} else {
				diag_val := grid[diag.x][diag.y]
				diag_same = diag_val == val
			}

			if neighbor_same[ind1] && neighbor_same[ind2] && !diag_same {
				// concave corner
				//   A A
				//   A B
				perimeter += 1
			}
		}
	}

	return
}

calculate_cost :: proc(input: string, num_sides := false) -> int {
	_input := input
	allocator := context.temp_allocator

	visited := make([dynamic][]bool, allocator)
	grid := make([dynamic]string, allocator)

	for line in strings.split_lines_iterator(&_input) {
		append(&grid, line)
		append(&visited, make([]bool, len(line), allocator))
	}

	sum := 0
	for row in 0 ..< len(grid) {
		for col in 0 ..< len(grid[0]) {
			if visited[row][col] do continue
			area, perim := flood_fill(Vec2{row, col}, grid[:], visited[:], num_sides, allocator)
			sum += area * perim
		}
	}

	return sum
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 12")
	fmt.println("Example 1-1: ", calculate_cost(example01), " (expected 140)")
	fmt.println("Example 1-2: ", calculate_cost(example02), " (expected 1930)")
	fmt.println("Input 1: ", calculate_cost(input))
	fmt.println("Example 2-1: ", calculate_cost(example01, true), " (expected 80)")
	fmt.println("Example 2-2: ", calculate_cost(example02, true), " (expected 1206)")
	fmt.println("Example 2-3: ", calculate_cost(example03, true), " (expected 368)")
	fmt.println("Input 2: ", calculate_cost(input, true))
}
