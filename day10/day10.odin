package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/*
0123
1234
8765
9876

X...
XXXX
XXXX
X...

X...
XXXX
.XXX
XX..

X...
XXXX
..XX
XXX.

X...
XXXX
...X
XXXX

*/

example01 := `0123
1234
8765
9876`


/*
89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732
*/

example02 := `89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732`


Vec2 :: distinct [2]int

Left :: Vec2{0, -1}
Down :: Vec2{1, 0}
Right :: Vec2{0, 1}
Up :: Vec2{-1, 0}

SearchMethod :: enum {
	DepthFirst,
	BreadthFirst,
}

directions :: [4]Vec2{Left, Down, Right, Up}

bfs :: proc(pos: Vec2, grid: [][]int, visited: [][]int) -> int {
	row, col := pos.x, pos.y
	num_rows, num_cols := len(grid), len(grid[0])

	queue := make([dynamic]Vec2, context.temp_allocator)
	visited[row][col] = 1
	append(&queue, pos)

	score := 0
	index := 0

	// clear visited
	for i in 0 ..< num_rows {
		for j in 0 ..< num_cols {
			visited[i][j] = 0
		}
	}

	for index < len(queue) {
		node := queue[index]
		val := grid[node.x][node.y]

		if val == 9 {
			score += 1
		}

		for dir in directions {
			nextpos := node + dir
			if nextpos.x < 0 || nextpos.x >= num_rows || nextpos.y < 0 || nextpos.y >= num_cols {
				continue
			}

			next := grid[nextpos.x][nextpos.y]

			if !(visited[nextpos.x][nextpos.y] == 0) && next == val + 1 {
				append(&queue, nextpos)
				visited[nextpos.x][nextpos.y] = 1
			}
		}
		index += 1
	}

	return score
}

dfs :: proc(pos: Vec2, grid: [][]int, ratings: [][]int) -> int {
	row, col := pos.x, pos.y
	num_rows, num_cols := len(grid), len(grid[0])
	val := grid[row][col]

	rating := 0
	for dir in directions {
		nextpos := pos + dir
		if nextpos.x < 0 || nextpos.x >= num_rows || nextpos.y < 0 || nextpos.y >= num_cols {
			continue
		}
		nextval := grid[nextpos.x][nextpos.y]

		if val == 8 && nextval == 9 {
			rating += 1
		} else if nextval == val + 1 {
			rating += dfs(nextpos, grid, ratings)
		}
	}

	ratings[row][col] = rating

	return rating
}

evaluate_trailheads :: proc(
	input: string,
	method := SearchMethod.BreadthFirst,
	allocator := context.allocator,
) -> int {
	_input := input
	grid := make([dynamic][]int, allocator)
	visited := make([dynamic][]int, allocator)
	trailheads := make([dynamic]Vec2, allocator)

	for line in strings.split_lines_iterator(&_input) {
		row := make([]int, len(line), allocator)
		visited_row := make([]int, len(line), allocator)
		for c, col in line {
			row[col] = int(c - '0')
			if row[col] == 0 {
				append(&trailheads, Vec2{len(grid), col})
			}
		}
		append(&grid, row)
		append(&visited, visited_row)
	}

	score := 0

	for trailhead in trailheads {
		trail_score: int
		switch method {
		case .BreadthFirst:
			trail_score = bfs(trailhead, grid[:], visited[:])
		case .DepthFirst:
			trail_score = dfs(trailhead, grid[:], visited[:])
		}
		score += trail_score
	}

	return score
}


main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")

	//fmt.println("Example 1-1: ", evaluate_trailheads(example01, .BreadthFirst), " (expected 1)")
	//fmt.println("Example 1-2: ", evaluate_trailheads(example02, .BreadthFirst), " (expected 36)")
	//fmt.println("Input 1: ", evaluate_trailheads(string(contents), .BreadthFirst))
	//fmt.println("Example 2-2: ", evaluate_trailheads(example01, .DepthFirst), " (expected 16)")
	//fmt.println("Example 2-2: ", evaluate_trailheads(example02, .DepthFirst), " (expected 81)")

	fmt.println("Input 2: ", evaluate_trailheads(string(contents), .DepthFirst))
}
