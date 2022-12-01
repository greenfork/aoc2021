import gleam/list
import gleam/string
import gleam/int
import gleam/result
import gleam/set.{Set}

// Row-major
type Heightmap {
  Heightmap(map: List(List(Int)), rows: Int, columns: Int)
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> find_low_points()
  |> calculate_rish_levels()
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input()
  |> find_basins()
  |> select_three_largest()
  |> multiply()
}

fn parse_input(input: String) -> Heightmap {
  let parse_line = fn(line: String) -> List(Int) {
    line
    |> string.split("")
    |> list.map(fn(ch) {
      assert Ok(n) = int.parse(ch)
      n
    })
  }
  let map =
    input
    |> string.split("\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.map(parse_line)
  Heightmap(
    map: map,
    rows: list.length(map),
    columns: list.first(map)
    |> result.unwrap([])
    |> list.length(),
  )
}

fn find_low_points(hm: Heightmap) -> List(Int) {
  let coords_list = find_low_point_coords(hm)
  list.map(
    coords_list,
    fn(coords) { heightmap_element(hm, coords.0, coords.1) },
  )
}

fn find_low_point_coords(hm: Heightmap) -> List(#(Int, Int)) {
  list.flat_map(
    list.range(0, hm.rows - 1),
    fn(row_idx) {
      list.filter_map(
        list.range(0, hm.columns - 1),
        fn(column_idx) {
          let neighbour_coords =
            heightmap_neighbour_coords(hm, row_idx, column_idx)
          let neighbours =
            list.map(
              neighbour_coords,
              fn(coords) { heightmap_element(hm, coords.0, coords.1) },
            )
          let element = heightmap_element(hm, row_idx, column_idx)
          case list.all(neighbours, fn(neighbour) { element < neighbour }) {
            True -> Ok(#(row_idx, column_idx))
            False -> Error(Nil)
          }
        },
      )
    },
  )
}

fn heightmap_neighbour_coords(
  hm: Heightmap,
  row: Int,
  column: Int,
) -> List(#(Int, Int)) {
  assert True = row >= 0 && row < hm.rows
  assert True = column >= 0 && column < hm.columns
  let row_neighbours = case column == 0 {
    True -> [#(row, 1)]
    False ->
      case column == hm.columns - 1 {
        True -> [#(row, hm.columns - 2)]
        False -> [#(row, column - 1), #(row, column + 1)]
      }
  }
  let column_neighbours = case row == 0 {
    True -> [#(1, column)]
    False ->
      case row == hm.rows - 1 {
        True -> [#(hm.rows - 2, column)]
        False -> [#(row - 1, column), #(row + 1, column)]
      }
  }
  list.append(row_neighbours, column_neighbours)
}

fn heightmap_element(hm: Heightmap, row: Int, column: Int) -> Int {
  assert True = row >= 0 && row < hm.rows
  assert True = column >= 0 && column < hm.columns
  assert Ok(row) = list.at(hm.map, row)
  assert Ok(element) = list.at(row, column)
  element
}

fn calculate_rish_levels(low_points: List(Int)) -> Int {
  int.sum(low_points) + list.length(low_points)
}

fn find_basins(hm: Heightmap) -> List(List(Int)) {
  let low_point_coords_list = find_low_point_coords(hm)
  list.map(
    low_point_coords_list,
    fn(low_point_coords) { find_basin_coords(hm, low_point_coords, set.new()) },
  )
  |> list.map(fn(set_of_coords) {
    set_of_coords
    |> set.fold(
      [],
      fn(memo, coords) { [heightmap_element(hm, coords.0, coords.1), ..memo] },
    )
  })
}

fn find_basin_coords(
  hm: Heightmap,
  starting_point: #(Int, Int),
  basin_coords_set: Set(#(Int, Int)),
) -> Set(#(Int, Int)) {
  let basin_coords_set = set.insert(basin_coords_set, starting_point)
  let neighbour_coords_list =
    heightmap_neighbour_coords(hm, starting_point.0, starting_point.1)
    |> list.filter(fn(coords) {
      heightmap_element(hm, coords.0, coords.1) != 9 && !set.contains(
        basin_coords_set,
        coords,
      )
    })

  list.fold(
    neighbour_coords_list,
    basin_coords_set,
    fn(memo, neighbour_coords) {
      set.union(memo, find_basin_coords(hm, neighbour_coords, memo))
    },
  )
}

fn select_three_largest(basins: List(List(Int))) -> List(List(Int)) {
  list.sort(
    basins,
    by: fn(a, b) { int.compare(list.length(b), list.length(a)) },
  )
  |> list.take(3)
}

fn multiply(largest_basins: List(List(Int))) -> Int {
  list.fold(largest_basins, 1, fn(memo, a) { memo * list.length(a) })
}
