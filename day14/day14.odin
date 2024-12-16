package main

import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/netpbm"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

example01 := `p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3`


Vec2 :: distinct [2]int

Robot :: struct {
	pos: Vec2,
	vel: Vec2,
}

predict :: proc(
	input: string,
	width: int,
	height: int,
	num_steps: int,
	allocator := context.allocator,
) -> int {
	_input := input
	robots := make(#soa[dynamic]Robot, allocator)
	defer delete(robots)

	// Load robots from file
	for line in strings.split_lines_iterator(&_input) {
		robot: Robot

		p_str, _, v_str := strings.partition(line, " ")
		_, _, p_str = strings.partition(p_str, "=")
		px, _, py := strings.partition(p_str, ",")
		robot.pos = Vec2{strconv.atoi(px), strconv.atoi(py)}

		_, _, v_str = strings.partition(v_str, "=")
		vx, _, vy := strings.partition(v_str, ",")
		robot.vel = Vec2{strconv.atoi(vx), strconv.atoi(vy)}
		append_soa(&robots, robot)
	}

	// create grid
	grid := make([][]int, height, allocator)

	// create buffer for image
	buf: bytes.Buffer
	bytes.buffer_init_allocator(&buf, width * height, width * height, allocator)
	filename := make([]u8, len("outputs/output00000.pbm"), allocator)

	for _, index in grid {
		grid[index] = make([]int, width, allocator)
	}
	defer {
		for row in grid do delete(row)
		delete(grid)
		delete(filename)
		bytes.buffer_destroy(&buf)
	}

	// image information
	header := image.Netpbm_Header {
		format   = .P1,
		width    = width,
		height   = height,
		channels = 1,
		depth    = 8,
	}

	info := image.Netpbm_Info{header}

	img := image.Image {
		width    = header.width,
		height   = header.height,
		depth    = header.depth,
		channels = header.channels,
		pixels   = buf,
		which    = .NetPBM,
		metadata = &info,
	}

	// Advance robots in time and update grid
	for step in 0 ..< num_steps {
		// clear grid
		for row, y in grid {
			for &val, x in row {
				val = 0
				buf.buf[y * width + x] = 1
			}
		}

		// move robots forward
		for &robot in robots[:] {
			robot.pos += robot.vel
			if robot.pos.x >= width {
				robot.pos.x -= width
			}
			if robot.pos.y >= height {
				robot.pos.y -= height
			}
			if robot.pos.x < 0 {
				robot.pos.x += width
			}
			if robot.pos.y < 0 {
				robot.pos.y += height
			}
			grid[robot.pos.y][robot.pos.x] += 1
			buf.buf[robot.pos.y * width + robot.pos.x] = 0
		}

		// write image to file so we can look for a christmas tree
		if step == 7092 {
			fmt.bprintf(filename, "outputs/output%05d.pbm", step)
			fmt.println(string(filename))
			err := netpbm.save_to_file(string(filename), &img)
			if err != nil {
				fmt.println(err)
			}
		}
	}

	safety_factor := 0

	quadrant_sums: [4]int
	mid_x := width / 2
	mid_y := height / 2

	for row, y in grid {
		for val, x in row {
			if x < mid_x && y < mid_y {
				quadrant_sums[0] += val
			} else if x < mid_x && y > mid_y {
				quadrant_sums[1] += val
			} else if x > mid_x && y < mid_y {
				quadrant_sums[2] += val
			} else if x > mid_x && y > mid_y {
				quadrant_sums[3] += val
			}
		}
	}

	return quadrant_sums[0] * quadrant_sums[1] * quadrant_sums[2] * quadrant_sums[3]
}


main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 14")

	example_width := 11
	example_height := 7
	input_width := 101
	input_height := 103
	steps := 100

	fmt.printfln(
		"Example 1: %v (expected 12)",
		predict(example01, example_width, example_height, steps),
	)

	fmt.printfln("Input 1: %v", predict(input, input_width, input_height, steps))
	fmt.printfln("Input 1: %v", predict(input, input_width, input_height, 20_000))

}
