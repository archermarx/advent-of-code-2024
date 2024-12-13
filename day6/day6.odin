package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:time"

example_1 :=
`....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...`

State::enum{
	Empty,
	Obstacle,
	SpecialObstacle,
	Visited,
}

Direction::enum {
	None = 0,
	Up,
	Down,
	Left,
	Right,
}

Cell::struct {
	state: State,
	last_dir: Direction,
}

Position::[2]int

EndState::enum {
	Ok,
	OutOfBounds,
	Loop,
}

Guard::struct {
	dir: Direction,
	pos: Position,
	start: Position,
}

Grid::struct {
	guard: Guard,
	rows:[][]Cell,
}

grid_dims::proc(grid: Grid) -> (int, int) {
	num_rows := len(grid.rows)
	num_cols := len(grid.rows[0])
	return num_rows, num_cols
}

create_grid::proc(input: string) -> Grid {
	rows: [dynamic][]Cell
	guard: Guard

	rownum := 0
	str := input
	for line in strings.split_lines_iterator(&str) {
		row := make([]Cell, len(line))
		for col in 0..<len(line) {
			switch(line[col]) {
			case '.': row[col] = { state = .Empty, last_dir = .None }
			case '#': row[col] = { state = .Obstacle, last_dir = .None }
			case '^':
				guard.pos = {rownum, col}
				guard.start = guard.pos
				guard.dir = Direction.Up
				row[col] = {State.Visited, guard.dir}
			}
		}
		append(&rows, row)
		rownum += 1
	}
	return {guard, rows[:]}
}

delete_grid::proc(grid: ^Grid) {
	for row in grid.rows do delete(row)
	delete(grid.rows)
}

clear_grid::proc(grid: ^Grid) {
	num_rows, num_cols := grid_dims(grid^)
	for i in 0..<num_rows {
		for j in 0..<num_cols {
			state := grid.rows[i][j].state
			if state == .Visited || state == .SpecialObstacle {
				grid.rows[i][j].state = .Empty
				grid.rows[i][j].last_dir = .None
			}
		}
	}
	grid.guard.pos = grid.guard.start
	grid.guard.dir = .Up
}

print_grid::proc(grid: Grid, buf: ^strings.Builder) {
	padding := 1

	// Draw top border
	fmt.sbprint(buf, '╭')
	for _ in 1..<(padding+1)*len(grid.rows[0]) + 1 {
		fmt.sbprint(buf, '─')
	}
	fmt.sbprintln(buf, '╮')

	for row, i in grid.rows {
		fmt.sbprint(buf, '│')
		for cell, j in row {
			c: rune
			if i == grid.guard.pos[0] && j == grid.guard.pos[1] {
				#partial switch(grid.guard.dir) {
				case .Left: c = '<'
				case .Right: c = '>'
				case .Up: c = '^'
				case .Down: c = 'v'
				}
				fmt.sbprintf(buf, "\e[1;31m%v\e[0m", c)
			} else {
				switch(cell.state) {
				case .Empty: fmt.sbprint(buf, "\e[0;30m.\e[0m")
				case .Visited: fmt.sbprint(buf, "\e[1;37mX\e[0m")
				case .Obstacle: fmt.sbprint(buf, "\e[1;34m#\e[0m")
				case .SpecialObstacle: fmt.sbprint(buf, "\e[1;34m0\e[0m")
				}
			}
			for _ in 0..<padding do fmt.sbprint(buf, ' ')
		}
		fmt.sbprintln(buf, '│')
	}

	// Draw bottom border
	fmt.sbprint(buf, '╰')
	for _ in 1..<(padding+1)*len(grid.rows[0]) + 1 {
		fmt.sbprint(buf, '─')
	}
	fmt.sbprintln(buf, '╯')

	str := strings.to_string(buf^)
	strings.builder_reset(buf)

	fmt.print(str)
}


step::proc(grid: ^Grid) -> (bool, EndState) {
	nrows, ncols := grid_dims(grid^)
	guard := &grid.guard
	row, col := guard.pos[0], guard.pos[1]
	next: Position
	#partial switch guard.dir {
	case .Up:    next = {row - 1, col}
	case .Down:  next = {row + 1, col}
	case .Left:  next = {row, col - 1}
	case .Right: next = {row, col + 1}
	}

	// Check for out of bounds
	if next[0] < 0 || next[0] >= nrows ||
	   next[1] < 0 || next[1] >= ncols {
		return false, .OutOfBounds
	}

	new := false
	status := EndState.Ok

	state := grid.rows[next[0]][next[1]].state
	if state == State.Obstacle || state == State.SpecialObstacle {
		// Check for obstacle and turn right if encountered
		#partial switch guard.dir {
		case .Up: 	 guard.dir = Direction.Right
		case .Down:  guard.dir = Direction.Left
		case .Left:  guard.dir = Direction.Up
		case .Right: guard.dir = Direction.Down
		}
	} else {
		// Move forward and increment visited
		new = grid.rows[next[0]][next[1]].state == .Empty
		if new {
			grid.rows[row][col].last_dir = guard.dir
		}
		grid.rows[next[0]][next[1]].state = .Visited
		grid.guard.pos = next
	}

	// Check for a loop -- is our current direction the same as when we were last here?
	row, col = grid.guard.pos[0], grid.guard.pos[1]
	if grid.guard.dir == grid.rows[row][col].last_dir {
		status = .Loop
	}

	return new, status
}

predict_route::proc(
	grid: ^Grid,
	positions: ^[dynamic]Position = nil,
	buf: ^strings.Builder = nil,
	visualize := false) -> (int, EndState) {

	nrows, ncols := grid_dims(grid^)
	if positions != nil do clear(positions)
	visited := 1
	end: EndState

	for count := 0;;count += 1{
		if (visualize && buf != nil) {
			print_grid(grid^, buf)
			fmt.printf("\e[%vA", nrows+2)
			time.sleep(5_000_000)
		}
		new: bool
		new, end = step(grid)
		if new {
			visited += 1
			if positions != nil do append(positions, grid.guard.pos)
		}
		// detect loops with a maximum step count
		if end != .Ok {
			break;
		}
	}

	if visualize do print_grid(grid^, buf)

	return visited, end
}

count_visited::proc(input: string, visualize := false) -> int {
	grid := create_grid(input)
	defer delete_grid(&grid)

	buf := strings.builder_make();
	defer strings.builder_destroy(&buf)
	visited, _ := predict_route(&grid, nil, &buf, visualize)

	return visited
}

find_loops::proc(input: string, visualize := false) -> int {
	grid := create_grid(input)
	defer delete_grid(&grid)

	buf := strings.builder_make();
	defer strings.builder_destroy(&buf)

	positions: [dynamic]Position
	defer delete(positions)

	num_rows, num_cols := grid_dims(grid)
	num_loops := 0

	predict_route(&grid, &positions, &buf)

	for pos, index in positions[:] {
		i, j := pos[0], pos[1]
		clear_grid(&grid)

		// set new obstacle and run course
		grid.rows[i][j].state = .SpecialObstacle
		_, endstate := predict_route(&grid, nil, &buf, visualize)

		// increment loop counter if we found a loop
		if endstate == .Loop do num_loops += 1
		fmt.printfln("\e[1;32mChecked position %v/%v. Found %v loops.\e[0m", index+1, len(positions), num_loops)
		fmt.print("\e[1A")
		if visualize do fmt.printf("\e[%dA", num_rows+2)
	}
	if visualize do fmt.printf("\e[%dB", num_rows+2)
	fmt.println()

	return num_loops
}

main::proc() {
	contents, ok := os.read_entire_file_from_filename("input_day6.txt")
	if !ok do panic("could not read file!")
	defer delete(contents)
	input := string(contents)

	visualize := true
	fmt.println("Day 6")
	fmt.println("Example 1: ", count_visited(example_1, visualize), "(expected 41)")
	fmt.println("Input 1: ", count_visited(input))
	fmt.println("Example 2: ", find_loops(example_1, visualize), "(expected 6)")
	fmt.println("Input 2: ", find_loops(input))
}
