package main

import "core:container/priority_queue"
import "core:fmt"
import "core:os"
import "core:strings"

example01 := `###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############`


example02 := `#################
#...#...#...#..E#
#.#.#.#.#.#.#.#.#
#.#.#.#...#...#.#
#.#.#.#.###.#.#.#
#...#.#.#.....#.#
#.#.#.#.#.#####.#
#.#...#.#.#.....#
#.#.#####.#.###.#
#.#.#.......#...#
#.#.###.#####.###
#.#.#...#.....#.#
#.#.#.#####.###.#
#.#.#.........#.#
#.#.#.#########.#
#S#.............#
#################`


Vec2 :: distinct [2]int

Node :: struct {
	pos: Vec2,
	dir: Vec2,
}

Path :: struct {
	using node: Node,
	cost:       int,
}

less :: proc(n1: Path, n2: Path) -> bool {
	return n1.cost < n2.cost
}

solve_maze :: proc(
	input: string,
	count_best := false,
	visualize := false,
	allocator := context.allocator,
) -> (
	score: int,
) {
	_input := input
	maze := make([dynamic][]u8, allocator)
	defer delete(maze)

	start_pos: Vec2
	end_pos: Vec2

	// Load maze
	y: int
	for line in strings.split_lines_iterator(&_input) {
		append(&maze, transmute([]u8)line)
		for tile, x in line {
			if tile == 'S' {
				start_pos = {x, y}
			} else if tile == 'E' {
				end_pos = {x, y}
			}
		}
		y += 1
	}

	rows, cols := len(maze), len(maze[0])

	// create priority queue for dijkstra's algorithm
	pq :: priority_queue
	queue := pq.Priority_Queue(Path){}

	pq.init(&queue, less, pq.default_swap_proc(Path), rows * cols, allocator)
	start := Node{start_pos, {1, 0}}
	pq.push(&queue, Path{start, 0})

	lowest_cost := make(map[Node]int, allocator)
	backtrack := make(map[Node]map[Node]bool, allocator)
	end_states := make(map[Node]bool, allocator)

	defer {
		for _, set in backtrack do delete(set)
		delete(backtrack)
		delete(lowest_cost)
		delete(end_states)
		pq.destroy(&queue)
	}

	max_score := 1000 * (rows + cols)
	score = max_score

	for pq.len(queue) > 0 {
		current := pq.pop(&queue)

		if current in lowest_cost && current.cost > lowest_cost[current] do continue
		lowest_cost[current] = current.cost

		if maze[current.pos.y][current.pos.x] == 'E' {
			if current.cost > score do break
			score = current.cost
			end_states[current] = true
		}

		// possible next moves
		left := Vec2{-current.dir.y, current.dir.x}
		right := Vec2{current.dir.y, -current.dir.x}
		next_nodes := [3]Path {
			{ 	// go forward
				pos  = current.pos + current.dir,
				dir  = current.dir,
				cost = current.cost + 1,
			},
			{ 	// turn left
				pos  = current.pos + left,
				dir  = left,
				cost = current.cost + 1001,
			},
			{ 	// turn right
				pos  = current.pos + right,
				dir  = right,
				cost = current.cost + 1001,
			},
		}

		for next in next_nodes {
			if maze[next.pos.y][next.pos.x] == '#' do continue
			lowest := lowest_cost[next] or_else max_score
			if next.cost > lowest do continue
			if next not_in backtrack do backtrack[next] = make(map[Node]bool, allocator)
			if next.cost < lowest {
				lowest_cost[next] = lowest
			}

			// add to queue
			(&backtrack[next])[current] = true
			pq.push(&queue, next)
		}
	}

	if !count_best {
		return score
	}

	// do backtracking
	counted := make([][]bool, rows, allocator)
	for row in 0 ..< rows {
		counted[row] = make([]bool, cols, allocator)
	}

	defer {
		for row in counted do delete(row)
		delete(counted)
	}

	tile_count := 0
	states := make([dynamic]Node, allocator)
	for state, _ in end_states {
		append(&states, state)
	}

	state_index := 0


	for state_index < len(states) {
		state := states[state_index]
		state_index += 1

		if !counted[state.pos.y][state.pos.x] {
			counted[state.pos.y][state.pos.x] = true
			tile_count += 1
		}

		if state in backtrack {
			for last, _ in backtrack[state] {
				append(&states, last)
			}
		}
	}

	if visualize {
		for row, y in maze {
			for tile, x in row {
				if counted[y][x] {
					fmt.printf("\x1b[31;1mO\x1b[0m")

				} else {
					fmt.printf("%c", tile)
				}
			}
			fmt.println()
		}
	}
	fmt.println()

	return tile_count
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.printfln("Example 1-1: %v (expected %v)", solve_maze(example01), 7036)
	fmt.printfln("Example 1-2: %v (expected %v)", solve_maze(example02), 11048)
	fmt.printfln("Input 1: %v", solve_maze(input))

	fmt.printfln(
		"Example 1-2: %v (expected %v)",
		solve_maze(example01, count_best = true, visualize = true),
		45,
	)
	fmt.printfln(
		"Example 2-2: %v (expected %v)",
		solve_maze(example02, count_best = true, visualize = true),
		64,
	)
	fmt.printfln("Input 2: %v", solve_maze(input, count_best = true))
}
