package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

import "../lib"

example := `190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20`


num_digits :: proc(num: int) -> int {
	return int(math.log10(f64(num))) + 1
}

endswith :: proc(num: int, suffix: int) -> bool {
	q, r := math.divmod(num - suffix, 10)
	return r == 0
}

equation_works :: proc(test_val: int, nums: []string, allow_concat := false) -> bool {
	tail := strconv.atoi(nums[len(nums) - 1])

	if len(nums) == 1 {
		return tail == test_val
	}

	head := nums[:len(nums) - 1]
	quotient, remainder := math.divmod(test_val, tail)

	if remainder == 0 && equation_works(quotient, head, allow_concat) do return true

	if allow_concat && endswith(test_val, tail) {
		left := test_val / lib.powi(10, num_digits(tail))
		if equation_works(left, head, allow_concat) do return true
	}

	return equation_works(test_val - tail, head, allow_concat)
}

analyze_equations :: proc(input: string, allow_concat := false) -> int {
	_input := input

	sum := 0
	for line in strings.split_lines_iterator(&_input) {
		teststr, _, numstrs := strings.partition(line, ":")
		test_val := strconv.atoi(teststr)
		fields := strings.fields(numstrs, context.temp_allocator)
		if equation_works(test_val, fields, allow_concat) {
			sum += test_val
		}
	}

	return sum
}

main :: proc() {
	defer free_all(context.temp_allocator)

	contents, ok := os.read_entire_file_from_filename("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Example 1: ", analyze_equations(example), " (expected 3749)")
	fmt.println("Input 1: ", analyze_equations(input))
	fmt.println(
		"Example 2: ",
		analyze_equations(example, allow_concat = true),
		" (expected 11387)",
	)
	fmt.println("Input 2: ", analyze_equations(input, allow_concat = true))
}
