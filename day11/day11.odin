package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

import "../lib"

example := `125 17`

split_num :: proc(num: int) -> (left: int, right: int, even: bool) {
	n := lib.digits(num)
	q, r := math.divmod(n, 2)
	if r == 1 do return

	pow := lib.powi(10, q)
	left = num / pow
	right = num - left * pow
	even = true
	return
}

add_stone :: proc(stones: ^map[int]int, stone: int, count: int) {
	if stone in stones {
		stones[stone] += count
	} else {
		stones[stone] = count
	}
}

iterate :: proc(
	stones: ^map[int]int,
	new_stones: ^map[int]int,
	allocator := context.allocator,
) -> int {

	// clear new stones counts
	for k, &count in new_stones {
		count = 0
	}

	total := 0
	num_stones := 0
	for stone, count in stones {
		num_stones += 1
		total += count
		if stone == 0 {
			add_stone(new_stones, 1, count)
			continue
		}

		left, right, even := split_num(stone)
		if even {
			add_stone(new_stones, left, count)
			add_stone(new_stones, right, count)
			total += count
			continue
		}

		add_stone(new_stones, stone * 2024, count)
	}

	return total
}

count_stones :: proc(input: string, max_depth: int, allocator := context.allocator) -> int {
	_input := input
	stones := make(map[int]int, allocator)
	new_stones := make(map[int]int, allocator)

	for field in strings.split_iterator(&_input, " ") {
		stone := strconv.atoi(field)
		add_stone(&stones, stone, 1)
	}

	count := 0
	for _ in 0 ..< max_depth {
		count = iterate(&stones, &new_stones, allocator)
		stones, new_stones = new_stones, stones
	}

	return count
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	alloc := context.temp_allocator

	fmt.println("Example 1: ", count_stones(example, 25, allocator = alloc), " (expected 55312)")
	fmt.println("Input 1: ", count_stones(input, 25, allocator = alloc))
	fmt.println("Input 2: ", count_stones(input, 75, allocator = alloc))
}
