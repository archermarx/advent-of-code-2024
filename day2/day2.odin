package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

example::
`7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9`

level_ok::proc(prev: int, cur: int, increasing: bool) -> bool {
	if  (cur == prev) ||
		(increasing && cur <= prev) ||
		(!increasing && cur >= prev) ||
		abs(cur - prev) > 3 {
		return false
	}
	return true
}

classify_report::proc(levels: []string, remove := -1) -> bool {
	firstindex := 1 if remove == 0 else 0
	secondindex := firstindex + 2 if remove == 1 else firstindex + 1

	first  := strconv.atoi(levels[firstindex])
	second := strconv.atoi(levels[secondindex])
	increasing := second > first

	prev := first
	for level, index in levels {
		if index < secondindex || index == remove {
			continue
		}
		cur := strconv.atoi(level)
		if !level_ok(prev, cur, increasing) {
			return false
		}
		prev = cur
	}

	return true
}

count_safe_reports::proc(contents: string, dampen:= false) -> int {
	context.allocator = context.temp_allocator

	lines := strings.split(contents, "\n")
	defer delete(lines)

	safe_reports := 0
	for line, index in lines {
		fields := strings.fields(line)
		defer delete(fields)
		if len(fields) == 0 {
			break
		}
		safe := classify_report(fields)
		if safe {
			safe_reports += 1
		} else if dampen {
			dampen: for _, index in fields {
				if classify_report(fields, remove=index) {
					safe_reports += 1
					break dampen
				}
			}
		}
	}
	return safe_reports
}

main::proc() {
	contents, ok := os.read_entire_file_from_filename("input")
	input := string(contents)
	defer delete(input)

	if !ok {
		fmt.eprintf("Could not read file!")
		os.exit(1)
	}

	fmt.println("Example 1: ", count_safe_reports(example), ", expected 2")
	fmt.println("Input 1: ", count_safe_reports(input))
	fmt.println("Example 2: ", count_safe_reports(example, dampen=true), ", expected 4")
	fmt.println("Input 2: ", count_safe_reports(input, dampen=true))
}
