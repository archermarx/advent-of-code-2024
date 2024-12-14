package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file_from_filename("input_day7.txt", context.temp_allocator)
	if !ok do panic("could not read file!")
	input := string(contents)

	fmt.println("Day 8!")
}
