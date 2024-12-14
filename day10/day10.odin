package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example01 := `0123
1234
8765
9876`


main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")

	fmt.println("Day 10!")
}
