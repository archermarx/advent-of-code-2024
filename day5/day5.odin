package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

/*
97,75,47,61,53,29,13


97|75
97|13
97|61
97|47
97|53
97|29
75|29
75|53
75|47
75|61
75|13
47|29
47|61
47|13
47|53
61|13
61|53
61|29
53|29
53|13
29|13
*/

example_1:=
`47|53
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

Empty::struct{}

Rules:: map[int]map[int]Empty

parse_rules::proc(input: string) -> Rules {
	rule_str := input
	rules: Rules 
	
	for line in strings.split_lines_iterator(&rule_str) {
		s1, _, s2 := strings.partition(line, "|")
		n1 := strconv.atoi(s1)
		n2 := strconv.atoi(s2)

		if !(n1 in rules) {
			rules[n1] = make(map[int]Empty)
		}

		if !(n2 in rules) {
			rules[n2] = make(map[int]Empty)
		}

		rule := &rules[n2]
		rule[n1] = Empty{}
	}
	return rules
}

/*
75 -> [
	47	
	23
],
47 -> [
	23
],
23 -> []

i.e. 75 must come before 47 and 23
47 must come before 23

23 -> [
	47, 
	75
],
47 -> [
	75
],
75 -> []

i.e. 23 must come after 47 and 25

*/

check_update::proc(rules: Rules, update: string, reorder_invalid := false) -> int {
	spl := strings.split(update, ",")
	nums := make([]int, len(spl))
	defer {
		delete(spl)
		delete(nums)
	}
	for s, index in spl {
		nums[index] = strconv.atoi(spl[index])
	}

	middle := nums[len(nums)/2]

	outer: for n, index in nums {
		if !(n in rules) {
			// no rule for n, skip
			continue
		}
		for m in nums[index+1:] {
			if m in rules[n] {
				// n must be before n -- failure
				middle = 0
				break outer
			}
		}
	}

	if !reorder_invalid {
		return middle
	}



	return 0
}

process_updates::proc(input: string, reorder_invalid := false) -> int {
	rule_str, _, update_str := strings.partition(input, "\n\n")

	rules := parse_rules(rule_str)
	defer {
		for _, rule in rules do delete(rule)
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

main::proc() {
	contents, ok := os.read_entire_file_from_filename("input_day5.txt")
	input := string(contents)
	defer delete(contents)

	if !ok {
		fmt.eprintf("Could not read file!")
		os.exit(1)
	}

	fmt.println("Example 1: ", process_updates(example_1), " (expected 143)")
	fmt.println("Input 1: ", process_updates(input))
	fmt.println("Example 2: ", process_updates(example_1, reorder_invalid=true), " (expected 123)")
	fmt.println("Input 2: ", process_updates(input, reorder_invalid=true))
}
