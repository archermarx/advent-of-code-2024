package libs

import "core:fmt"
import "core:math"
import "core:mem"

powi :: proc(x: $T1, n: $T2) -> int {
	_x := int(x)
	switch n {
	case 0:
		return 1
	case 1:
		return _x
	case 2:
		return _x * _x
	case 3:
		return _x * _x * _x
	case 4:
		return _x * _x * _x * _x
	case:
		q, r := math.divmod(n, 2)
		if r == 0 {
			return powi(_x * _x, q)
		} else {
			return _x * powi(_x * _x, q)
		}
	}
}

digits :: proc(num: $T) -> int {
	return int(math.log10(f64(num))) + 1
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
