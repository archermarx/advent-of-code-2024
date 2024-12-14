package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

/*
Example: should give 11
3   4
4   3
2   5
1   3
3   9
3   3
*/
list1 := []int{3, 4, 2, 1, 3, 3}
list2 := []int{4, 3, 5, 3, 9, 3}

readlists :: proc(filename: string) -> (list1: [dynamic]int, list2: [dynamic]int, ok: bool) {
	filecontents := os.read_entire_file_from_filename(filename) or_return
	defer delete(filecontents)

	it := string(filecontents)
	for line in strings.split_lines_iterator(&it) {
		context.allocator = context.temp_allocator
		spl := strings.fields(line)
		defer delete(spl)
		append(&list1, strconv.atoi(spl[0]))
		append(&list2, strconv.atoi(spl[1]))
	}

	return list1, list2, true
}

sumdistances :: proc(list1: []int, list2: []int) -> int {
	slice.sort(list1)
	slice.sort(list2)

	sum := 0
	for dist1, index in list1 {
		dist2 := list2[index]
		sum += abs(dist1 - dist2)
	}

	return sum
}

similarityscore :: proc(list1: []int, list2: []int) -> int {
	slice.sort(list1)
	slice.sort(list2)

	counts := make(map[int]int)
	defer delete(counts)

	for num2 in list2 {
		if num2 in counts {
			counts[num2] += 1
		} else {
			counts[num2] = 1
		}
	}

	score := 0
	for num1 in list1 {
		score += num1 * counts[num1]
	}

	return score
}

day1_1 :: proc(filename: string) -> int {
	list1, list2, ok := readlists(filename)
	if !ok {return -1}
	return sumdistances(list1[:], list2[:])
}

main :: proc() {
	arr1, arr2, ok := readlists("input")
	defer {
		delete(arr1)
		delete(arr2)
	}

	fmt.println("Example 1: ", sumdistances(list1, list2), ", Expected 11")
	fmt.println("Input 1: ", sumdistances(arr1[:], arr2[:]))
	fmt.println("Example 2: ", similarityscore(list1, list2), ", Expected 31")
	fmt.println("Input 1: ", similarityscore(arr1[:], arr2[:]))
}
