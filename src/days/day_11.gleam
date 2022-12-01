import gleam/list
import gleam/string
import gleam/int
import gleam/io
import gleam/iterator
import gleam/map.{Map}
import gleam/order.{Eq}
import gleam/option.{None, Some}
import shellout

pub type Octopus {
  Octopus(energy: Int, flashed: Bool)
}

pub type Coord {
  Coord(row: Int, col: Int)
}

pub type Cavern {
  Cavern(octopi: Map(Coord, Octopus), rows: Int, cols: Int)
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> iterator.iterate(simulate_single_step)
  // |> iterator.map(print_cavern)
  |> iterator.map(count_flashes)
  // |> iterator.map(io.debug)
  |> iterator.take(101)
  |> iterator.fold(0, int.add)
}

pub fn pt_2(input: String) -> Int {
  let step_no =
    input
    |> parse_input()
    |> iterator.iterate(simulate_single_step)
    |> iterator.index()
    |> iterator.drop_while(fn(idx_cavern) { count_flashes(idx_cavern.1) < 100 })
    |> iterator.first()
  assert Ok(step_no) = step_no
  step_no.0
}

fn parse_input(input: String) -> Cavern {
  let octopi_list =
    string.split(input, "\n")
    |> list.filter_map(fn(line) {
      case line {
        "" -> Error(Nil)
        line ->
          Ok(
            string.split(line, "")
            |> list.map(fn(ch) {
              assert Ok(n) = int.parse(ch)
              Octopus(n, False)
            }),
          )
      }
    })
  let octopi =
    list.index_fold(
      octopi_list,
      map.new(),
      fn(memo, row, row_idx) {
        list.index_fold(
          row,
          memo,
          fn(map, octopus, col_idx) {
            map.insert(map, Coord(row_idx, col_idx), octopus)
          },
        )
      },
    )
  assert Ok(first_row) = list.first(octopi_list)
  let cavern =
    Cavern(
      octopi: octopi,
      rows: list.length(octopi_list),
      cols: list.length(first_row),
    )
  assert True = cavern.rows > 0
  assert True = cavern.cols > 0
  cavern
}

fn simulate_single_step(cavern: Cavern) -> Cavern {
  let octopi =
    cavern.octopi
    |> map.map_values(fn(_, octopus) {
      Octopus(..octopus, energy: octopus.energy + 1)
    })
  let octopi = flash(octopi, cavern.rows, cavern.cols)
  let octopi =
    octopi
    |> map.map_values(fn(_, octopus) {
      case octopus.energy > 9 {
        True -> Octopus(energy: 0, flashed: False)
        False -> octopus
      }
    })
  Cavern(..cavern, octopi: octopi)
}

fn flash(
  octopi: Map(Coord, Octopus),
  rows: Int,
  cols: Int,
) -> Map(Coord, Octopus) {
  let going_to_flash =
    map.filter(
      octopi,
      fn(_, octopus) { octopus.energy > 9 && !octopus.flashed },
    )
  case map.size(going_to_flash) == 0 {
    True -> octopi
    False ->
      flash(
        list.fold(
          map.keys(going_to_flash),
          octopi,
          fn(memo, coord) {
            let adjacent = adjacent_coords(coord, rows, cols)
            list.fold(
              adjacent,
              memo,
              fn(map, adjacent_coord) {
                map.update(
                  map,
                  adjacent_coord,
                  fn(octo) {
                    case octo {
                      Some(octo) -> Octopus(..octo, energy: octo.energy + 1)
                      None -> {
                        assert True = False
                        Octopus(0, False)
                      }
                    }
                  },
                )
              },
            )
            |> map.update(
              coord,
              fn(octo) {
                case octo {
                  Some(octo) -> Octopus(..octo, flashed: True)
                  None -> {
                    assert True = False
                    Octopus(0, False)
                  }
                }
              },
            )
          },
        ),
        rows,
        cols,
      )
  }
}

fn count_flashes(cavern: Cavern) -> Int {
  map.fold(
    cavern.octopi,
    0,
    fn(memo, _coord, octo) {
      case octo.energy == 0 {
        True -> memo + 1
        False -> memo
      }
    },
  )
}

fn adjacent_coords(coord: Coord, rows: Int, cols: Int) -> List(Coord) {
  let possibly_adjacent = [
    Coord(coord.row - 1, coord.col - 1),
    Coord(coord.row - 1, coord.col),
    Coord(coord.row - 1, coord.col + 1),
    Coord(coord.row, coord.col - 1),
    Coord(coord.row, coord.col + 1),
    Coord(coord.row + 1, coord.col - 1),
    Coord(coord.row + 1, coord.col),
    Coord(coord.row + 1, coord.col + 1),
  ]
  list.filter_map(
    possibly_adjacent,
    fn(coord) {
      case
        coord.row >= 0 && coord.row < rows && coord.col >= 0 && coord.col < cols
      {
        True -> Ok(coord)
        False -> Error(coord)
      }
    },
  )
}

pub fn print_cavern(cavern: Cavern) -> Cavern {
  io.println("Step:")
  map.to_list(cavern.octopi)
  |> list.sort(fn(a, b) {
    let coord_a = a.0
    let coord_b = b.0
    case int.compare(coord_a.row, coord_b.row) {
      Eq -> int.compare(coord_a.col, coord_b.col)
      any -> any
    }
  })
  |> list.chunk(fn(octo_pair) {
    let coord = octo_pair.0
    coord.row
  })
  |> list.map(fn(octo_pair_list) {
    list.map(octo_pair_list, fn(octo_pair) { octo_pair.1 })
  })
  |> iterator.from_list()
  |> iterator.map(fn(line) {
    iterator.from_list(line)
    |> iterator.map(fn(octo) {
      case octo.energy {
        0 ->
          int.to_string(octo.energy)
          |> shellout.style(with: shellout.color(["green"]), custom: [])
        _ -> int.to_string(octo.energy)
      }
      |> io.print()
    })
    |> iterator.run()
    io.println("")
  })
  |> iterator.run()
  cavern
}
