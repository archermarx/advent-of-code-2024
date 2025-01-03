package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example_1 := `47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47`


Empty :: struct {}
Rule :: map[int]Empty

make_rules :: proc(input: string) -> []Rule {
	rule_str := input
	rules := make([dynamic]Rule, 128)

	for line in strings.split_lines_iterator(&rule_str) {
		s1, _, s2 := strings.partition(line, "|")
		n1 := strconv.atoi(s1)
		n2 := strconv.atoi(s2)

		if rules[n1] == nil {
			rules[n1] = make(map[int]Empty)
		}

		if rules[n2] == nil {
			rules[n2] = make(map[int]Empty)
		}

		rule := &rules[n2]
		rule[n1] = Empty{}
	}
	return rules[:]
}

check_update :: proc(rules: []Rule, update: string, reorder_invalid := false) -> int {
	N := strings.count(update, ",") + 1
	nums := make([]int, N)
	defer delete(nums)

	index := 0
	str := update

	for s in strings.split_iterator(&str, ",") {
		nums[index] = strconv.atoi(s)
		index += 1
	}

	sorted := false
	step := 0
	for ; !sorted; step += 1 {
		sorted = true
		for i in 0 ..< N - 1 {
			n := nums[i]
			m := nums[i + 1]
			if m in rules[n] {
				sorted = false
				nums[i] = m
				nums[i + 1] = n
			}
		}
	}

	if !reorder_invalid {
		if step == 1 {
			return nums[N / 2]
		}
		return 0
	} else {
		if step == 1 {
			return 0
		}
		return nums[N / 2]
	}
}

process_updates :: proc(input: string, reorder_invalid := false) -> int {
	rule_str, _, update_str := strings.partition(input, "\n\n")

	rules := make_rules(rule_str)
	defer {
		for rule in rules do delete(rule)
		delete(rules)
	}

	sum := 0
	index := 0
	for line in strings.split_lines_iterator(&update_str) {
		middle := check_update(rules, line, reorder_invalid)
		sum += middle
		index += 1
	}

	return sum
}

main :: proc() {
	contents, ok := os.read_entire_file_from_filename("input")
	if !ok do panic("could not read file!")
	defer delete(contents)
	input := string(contents)

	fmt.println("Example 1: ", process_updates(example_1), " (expected 143)")
	fmt.println("Input 1: ", process_updates(input))
	fmt.println(
		"Example 2: ",
		process_updates(example_1, reorder_invalid = true),
		" (expected 123)",
	)
	fmt.println("Input 2: ", process_updates(input, reorder_invalid = true))
}
