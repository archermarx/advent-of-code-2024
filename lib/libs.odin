package libs

import "core:fmt"
import "core:mem"

powi :: proc(a: int, b: int) -> int {
	switch b {
	case 0:
		return 1
	case 1:
		return a
	case 2:
		return a * a
	case 3:
		return a * a * a
	case 4:
		return a * a * a * a
	case:
		{
			return powi(a * a, b - 2)
		}
	}
}

new_tracking_allocator :: proc() -> ^mem.Tracking_Allocator {
	track: ^mem.Tracking_Allocator = new(mem.Tracking_Allocator)
	mem.tracking_allocator_init(track, context.allocator)
	return track
}

check_leaks :: proc(track: ^mem.Tracking_Allocator) {
	if len(track.allocation_map) > 0 {
		fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
		}
	}
	if len(track.bad_free_array) > 0 {
		fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
	mem.tracking_allocator_destroy(track)
	free(track)
}
