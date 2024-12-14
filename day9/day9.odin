package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

example := "2333133121414131402"
decompressed := "00...111...2...333.44.5555.6666.777.888899"
example2 := "151010"
// 0.....12
// 02....1.
// 021.....
// checksum = 0*0 + 2*1 + 1*2 = 4
checksum2 := 4

example3 := "1313165"
// 0...1...2......33333
// 0...1...233333......
// 02..1....33333......
checksum3 := 169

example4 := "2833133121414131402"
// 
checksum4 := 2184

Span :: struct {
	start: int,
	len:   int,
}

FreeBlock :: struct {
	span: []int,
	next: ^FreeBlock,
}

decompress :: proc(input: string, allocator := context.allocator) -> ([]int, []Span) {
	size := 0
	num_files := 0
	blank := false
	for c in input {
		if c == '\n' do break
		if !blank {
			num_files += 1
		}
		blank = !blank
		size += int(c - '0')
	}

	blocks := make([]int, size, allocator)
	files := make([]Span, num_files, allocator)

	pos := 0
	fileid := 0
	blank = false
	for c in input {
		if c == '\n' do break
		block_size := int(c - '0')
		for i in 0 ..< block_size {
			blocks[pos + i] = -1 if blank else fileid
		}
		if !blank {
			files[fileid] = Span{pos, block_size}
			fileid += 1
		}
		pos += block_size
		blank = !blank
	}

	return blocks, files
}

defragment :: proc(input: string) -> int {
	blocks, files := decompress(input, context.temp_allocator)

	first_empty := 0
	#reverse for file, index in files {
		if index < 1 do break

		span := Span {
			start = -1,
			len   = 0,
		}

		seen_empty := false
		for i in first_empty ..< len(blocks) {
			if i >= file.start do break
			if blocks[i] < 0 {
				if span.start < 0 {
					span.start = i
				}
				if seen_empty {
					first_empty = i
					seen_empty = true
				}
				span.len += 1

				if span.len == file.len {
					for j in 0 ..< file.len {
						blocks[j + span.start] = blocks[j + file.start]
						blocks[j + file.start] = -1
					}
					break
				}
			} else {
				span.start = -1
				span.len = 0
			}
		}
	}

	// compute checksum
	checksum := 0
	for num, i in blocks {
		//fmt.print(rune(num + '0') if num >= 0 else '.')
		if num < 0 do continue
		checksum += num * i
	}
	//fmt.println()

	return checksum
}

free_space :: proc(input: string) -> int {
	blocks, _ := decompress(input, context.temp_allocator)

	// defragment and compute checksum
	checksum := 0
	end := len(blocks) - 1
	for i := 0; i < end; i += 1 {
		if blocks[i] < 0 {
			// swap this empty block with last nonempty block
			for blocks[end] < 0 do end -= 1
			if end <= i do break
			blocks[i] = blocks[end]
			blocks[end] = -1
		}
		checksum += i * blocks[i]
	}

	return checksum
}

main :: proc() {
	defer free_all(context.temp_allocator)
	contents, ok := os.read_entire_file("input", context.temp_allocator)
	if !ok do panic("could not read file!")
	// strip trailing newline
	input := strings.split_n(string(contents), "\n", 1)[0]

	fmt.println("Example 1: ", free_space(example), " (expected 1928)")
	fmt.println("Example 1.1: ", free_space(example2), "(expected", checksum2, ")")
	fmt.println("Input 1: ", free_space(input))
	fmt.println("Example 2: ", defragment(example), " (expected 2858)")
	fmt.println("Example 2.1: ", defragment(example2), "(expected", checksum2, ")")
	fmt.println("Example 2.2: ", defragment(example3), "(expected", checksum3, ")")
	fmt.println("Example 2.3: ", defragment(example4), "(expected", checksum4, ")")
	fmt.println("Input 2: ", defragment(input))
}
