package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example01 := `
Register A: 0
Register B: 0
Register C: 9

Program: 2,6`


example02 := `Register A: 10
Register B: 0
Register C: 0

Program: 5,0,5,1,5,4`


example03 := `Register A: 2024
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0`


example04 := `Register A: 0
Register B: 29
Register C: 0

Program: 1,7`


example05 := `Register A: 0
Register B: 2024
Register C: 43690

Program: 4,0`


example06 := `Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0`


example07 := `Register A: 117440
Register B: 0
Register C: 0

Program: 0,3,5,4,3,0`


Op :: enum {
	adv = 0, // divide A by 2^(combo operand), truncate, write to A
	bxl = 1, // bitwise XOR of B and literal operand, write to B
	bst = 2, // store combo operand % 8 in register B
	jnz = 3, // if A is nonzero, set IP to literal operand
	bxc = 4, // bitwise XOR of B and C, store in B. read and ignore operand
	out = 5, // output combo operand, mod 8
	bdv = 6, // same as adv, but store in A
	cdv = 7, // same as bdv, but store in B
}

Computer :: struct {
	ip:      uint,
	A:       uint,
	B:       uint,
	C:       uint,
	program: [dynamic]uint,
	output:  [dynamic]uint,
}

read_field :: proc(s: string, delim: string) -> (string, string) {
	key, _, val := strings.partition(s, delim)
	return strings.trim_space(key), strings.trim_space(val)
}

read_uint :: proc(s: string, delim: string) -> (n: uint, str: string, ok: bool) {
	head, tail := read_field(s, delim)

	n, ok = strconv.parse_uint(head)
	if ok {
		return n, tail, true
	} else {
		return 0, s, false
	}
}

combo_operand :: proc(computer: Computer, operand: uint) -> uint {
	if operand < 4 do return operand
	if operand == 4 do return computer.A
	if operand == 5 do return computer.B
	if operand == 6 do return computer.C
	panic("Encountered invalid combo operand!")
}

execute_fast :: proc(A: uint, out: ^[16]uint) -> int {
	i := 0
	out^ = {}
	// manually compiled example program
	#no_bounds_check for A := A; A != 0; A = A >> 3 {
		res := A ~ (A >> (A % 8 ~ 7))
		out[i] = res % 8
		i += 1
	}
	return i
}

prog_len :: 16

check_A :: proc(A: uint) -> bool {
	@(static) target := [?]uint{2, 4, 1, 7, 7, 5, 0, 3, 4, 0, 1, 7, 5, 5, 3, 0}
	@(static) out: [len(target)]uint
	out_len := execute_fast(A, &out)

	fmt.println(out)
	for i := 1; i <= out_len; i += 1 {
		if out[out_len - i] != target[len(target) - i] {
			return false
		}
	}
	return true
}

search_progs :: proc(left: uint = 0, octal: uint = 0) -> uint {
	if octal == 16 do return left

	for i in 0 ..< 8 {
		if i == 0 && left == 0 do continue
		A := (left << 3) + uint(i)
		fmt.printfln("0o%o", A)
		if check_A(A) {
			result := search_progs(A, octal + 1)
			if result > 0 {
				return result
			}
		}
	}
	return 0
}

run_program :: proc(program: string, allocator := context.allocator) {
	computer: Computer

	A_reg, B_reg, C_reg: string
	program := program
	A_reg, _, program = strings.partition(program, "\n")
	B_reg, _, program = strings.partition(program, "\n")
	C_reg, _, program = strings.partition(program, "\n")
	_, _, program = strings.partition(program, "\n")
	_, program = read_field(program, ":")


	_, A_reg = read_field(A_reg, ":")
	_, B_reg = read_field(B_reg, ":")
	_, C_reg = read_field(C_reg, ":")

	computer.A = strconv.parse_uint(A_reg) or_else 0
	computer.B = strconv.parse_uint(B_reg) or_else 0
	computer.C = strconv.parse_uint(C_reg) or_else 0

	computer.program = make([dynamic]uint, allocator)
	defer delete(computer.program)
	for len(program) > 0 {
		n: uint
		n, program = read_uint(program, ",") or_break
		append(&computer.program, n)
	}

	step := 0
	max_steps := 10_000

	computer.output = make([dynamic]uint, allocator)
	defer delete(computer.output)
	loop: for computer.ip + 1 < len(computer.program) && step < max_steps {
		op := Op(computer.program[computer.ip])
		operand := computer.program[computer.ip + 1]
		computer.ip += 2
		step += 1

		store_loc: ^uint

		switch op {
		case .adv:
			operand = combo_operand(computer, operand)
			computer.A = computer.A / (1 << operand)
		case .bdv:
			operand = combo_operand(computer, operand)
			computer.B = computer.A / (1 << operand)
		case .cdv:
			operand = combo_operand(computer, operand)
			computer.C = computer.A / (1 << operand)
		case .bxl:
			computer.B ~= operand
		case .bst:
			computer.B = combo_operand(computer, operand) % 8
		case .jnz:
			if computer.A != 0 do computer.ip = operand
		case .bxc:
			computer.B ~= computer.C
		case .out:
			append(&computer.output, combo_operand(computer, operand) % 8)
		}
	}
	if step >= max_steps {
		fmt.printfln("\x1b[31;1mProgram exceeded maximum run-time of %v steps.\x1b[0m", max_steps)
	} else {
		fmt.printfln("\x1b[32;1mProgram completed in %v steps\x1b[0m", step)
	}
	print_computer(computer)
}

print_computer :: proc(comp: Computer) {
	fmt.printfln("Register A: %v", comp.A)
	fmt.printfln("Register B: %v", comp.B)
	fmt.printfln("Register C: %v", comp.C)
	fmt.println()
	fmt.printfln("Program: %v", comp.program[:])
	fmt.printfln("Ip: %v", comp.ip)
	fmt.printfln("Output: %v\n", comp.output[:])
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)
	alloc := context.temp_allocator

	fmt.printfln("Example 1-1: (expected %v)", "B = 1")
	run_program(example01)
	fmt.printfln("Example 1-2: (expected %v)", "0,1,2")
	run_program(example02)
	fmt.printfln("Example 1-3: (expected %v)", "4,2,5,6,7,7,7,7,3,1,0; A = 0")
	run_program(example03)
	fmt.printfln("Example 1-4: (expected %v)", "B = 26")
	run_program(example04)
	fmt.printfln("Example 1-5: (expected %v)", "B = 44534")
	run_program(example05)
	fmt.printfln("Example 1-6: (expected %v)", "4,6,3,5,6,3,5,2,1,0")
	run_program(example06)

	fmt.printfln("Input 1")
	run_program(input)

	fmt.printfln("Fast prog: %v", search_progs())
}
