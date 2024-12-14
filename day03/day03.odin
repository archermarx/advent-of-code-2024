package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Do :: struct {
	text: string,
}

Dont :: struct {
	text: string,
}

Mul :: struct {
	left:  int,
	right: int,
	text:  string,
}

Op :: union {
	Do,
	Dont,
	Mul,
}

example_1 := "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
example_2 := "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"
example_muls := []Mul {
	{2, 4, "mul(2,4)"},
	{5, 5, "mul(5,5)"},
	{11, 8, "mul(11,8)"},
	{8, 5, "mul(8,5)"},
}

isdigit :: proc(b: u8) -> bool {
	return b >= '0' && b <= '9'
}

match_char :: proc(text: string, pos: ^int, c: u8) -> bool {
	if pos^ >= len(text) do return false

	if text[pos^] == c {
		pos^ += 1
		return true
	} else {
		return false
	}
}

match_num :: proc(text: string, pos: ^int) -> (num: int, ok: bool) {
	if pos^ >= len(text) do return

	start := pos^
	for ; isdigit(text[pos^]); pos^ += 1 do continue
	if pos^ == start do return

	return strconv.atoi(text[start:pos^]), true
}

match_do_dont :: proc(text: string, pos: ^int) -> (op: Op, ok: bool) {
	start := pos^

	match_char(text, pos, 'd') or_return
	match_char(text, pos, 'o') or_return
	if pos^ < len(text) && text[pos^] == 'n' {
		// don't
		op = Dont{}
		match_char(text, pos, 'n') or_return
		match_char(text, pos, '\'') or_return
		match_char(text, pos, 't') or_return
	} else {
		op = Do{}
	}
	match_char(text, pos, '(') or_return
	match_char(text, pos, ')') or_return
	return op, true
}

match_mul :: proc(text: string, pos: ^int) -> (op: Op, ok: bool) {
	start := pos^
	// 'm' 'u' 'l' '('
	match_char(text, pos, 'm') or_return
	match_char(text, pos, 'u') or_return
	match_char(text, pos, 'l') or_return
	match_char(text, pos, '(') or_return

	mul: Mul

	// Check for number, ',', number
	mul.left = match_num(text, pos) or_return
	match_char(text, pos, ',') or_return
	mul.right = match_num(text, pos) or_return

	// Closing paren
	match_char(text, pos, ')') or_return

	// Capture text for debugging
	mul.text = text[start:pos^]

	return mul, true
}

next_op :: proc(text: string, pos: ^int) -> (op: Op, ok: bool) {
	for pos^ < len(text) {
		// Find next `m` or 'd'
		for ; pos^ < len(text) && text[pos^] != 'm' && text[pos^] != 'd'; pos^ += 1 do continue

		op, ok := match_mul(text, pos)
		if ok {
			return op, true
		}
		op, ok = match_do_dont(text, pos)
		if ok {
			return op, true
		}
	}
	return
}

add_muls :: proc(text: string, ignore_do: bool = true) -> int {
	sum := 0
	pos := 0
	multiply := true
	for {
		op := next_op(text, &pos) or_break
		switch o in op {
		case Do:
			multiply = true
		case Dont:
			multiply = false
		case Mul:
			if multiply || ignore_do do sum += o.left * o.right
		}
	}
	return sum
}

main :: proc() {
	contents, ok := os.read_entire_file_from_filename("input")
	input := string(contents)
	defer delete(input)

	if !ok {
		fmt.eprintf("Could not read file!")
		os.exit(1)
	}

	fmt.println("Example 1: ", add_muls(example_1), " (expected 161)")
	fmt.println("Input 1: ", add_muls(input))
	fmt.println("Example 2: ", add_muls(example_2, ignore_do = false), " (expected 48)")
	fmt.println("Input 2: ", add_muls(input, ignore_do = false))
}
