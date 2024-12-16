package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"

Prize :: distinct [2]int
Button :: distinct [2]int

example01 := `Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279
`


// For buttons A and B, and prize at P, the solution is possible iff there exist a and b such that
// a*A + b*B = P, or 
// {
// 	a*A.x + b*B.x = P.x,
//  a*A.y + b*B.y = P.y
// }
// The cost of the solution is a*A.cost + b*B.cost
// 
// Substitution:
// 	1. a = (P.x - b*B.x)/A.x
//  (P.x - b*B.x)*A.y/A.x + b*B.y = P.y
//  b(B.y - A.y/A.x * B.x) = P.y - P.x * A.y/A.x
// 	b = (P.y - P.x * A.y/A.x) / (B.y - B.x * A.y/A.x)
//  b = (A.x * P.y - A.y * P.x) / (A.x * B.y - A.y * B.x)

calculate_cost :: proc(A: Button, B: Button, P: Prize) -> int {
	b, b_rem := math.divmod(A.x * P.y - A.y * P.x, A.x * B.y - A.y * B.x)
	a, a_rem := math.divmod(P.x - b * B.x, A.x)
	if a * A + b * B != Button(P) {
		return 0
	}

	return 3 * a + b
}

CONST := 10000000000000

parse_claw_machine :: proc(input: string, add := false) -> (A: Button, B: Button, P: Prize) {
	_input := input
	for line in strings.split_lines_iterator(&_input) {
		field, _, coords := strings.partition(line, ": ")
		x_str, _, y_str := strings.partition(coords, ", ")

		if field == "Prize" {
			_, _, x := strings.partition(x_str, "=")
			_, _, y := strings.partition(y_str, "=")
			P.x = strconv.atoi(x)
			P.y = strconv.atoi(y)
			if add {
				P.x += CONST
				P.y += CONST
			}
		} else {
			_, _, x := strings.partition(x_str, "+")
			_, _, y := strings.partition(y_str, "+")
			button := Button{strconv.atoi(x), strconv.atoi(y)}
			if field == "Button A" do A = button
			if field == "Button B" do B = button
		}
	}
	return A, B, P
}

calculate_total_cost :: proc(input: string, add := false) -> int {
	remainder := input
	total_cost := 0

	for {
		machine, mid: string
		machine, mid, remainder = strings.partition(remainder, "\n\n")
		if len(machine) == 0 {
			break
		}

		A, B, P := parse_claw_machine(machine, add)
		total_cost += calculate_cost(A, B, P)
	}

	return total_cost
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 13!")
	fmt.println("Example 1: ", calculate_total_cost(example01), "(expected 480)")
	fmt.println("Input 1: ", calculate_total_cost(input), "(expected 28138)")
	fmt.println("Input 2: ", calculate_total_cost(input, add = true))
}
