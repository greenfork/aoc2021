//// Uses broken and probably slow Dijstra's shortest path algorithm.

import gleam/list
import gleam/string
import gleam/int
import gleam/io
import gleam/iterator
import gleam/map.{Map}
import shellout

pub type Coordinate {
  C(x: Int, y: Int)
}

pub type Dimensions {
  Dimensions(x: Int, y: Int)
}

pub type Cell {
  Cell(min_cost: Int, risk_level: Int, shortest_path: List(Coordinate))
}

pub type Cells =
  Map(Coordinate, Cell)

pub type Cavern {
  Cavern(cells: Cells, dimensions: Dimensions)
}

type PriorityQueueItem {
  PriorityQueueItem(
    coord: Coordinate,
    running_cost: Int,
    running_path: List(Coordinate),
  )
}

type PriorityQueue {
  PriorityQueue(items: List(PriorityQueueItem), sorted: Bool)
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input
  |> traverse
  |> correct_free_first_cell
  // |> print_cavern(fn(cell) { int.to_string(cell.risk_level) })
  |> path_cost
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input
  |> enlarge_cavern(times: 3)
  |> traverse
  |> correct_free_first_cell
  |> print_cavern(fn(cell) { int.to_string(cell.risk_level) })
  |> print_end_cell
  |> path_cost
}

fn traverse(cavern: Cavern) -> Cavern {
  let starting_coord = C(0, 0)
  let pq =
    PriorityQueue(
      items: [
        PriorityQueueItem(
          coord: starting_coord,
          running_cost: 0,
          running_path: [],
        ),
      ],
      sorted: True,
    )

  do_traverse(cavern, pq)
}

fn print_end_cell(cavern: Cavern) -> Cavern {
  let ending_coord = C(cavern.dimensions.x - 1, cavern.dimensions.y - 1)
  assert Ok(ending_cell) = map.get(cavern.cells, ending_coord)
  io.debug(ending_cell)
  cavern
}

fn path_cost(cavern: Cavern) -> Int {
  let ending_coord = C(cavern.dimensions.x - 1, cavern.dimensions.y - 1)
  assert Ok(ending_cell) = map.get(cavern.cells, ending_coord)
  ending_cell.min_cost
}

fn do_traverse(cavern: Cavern, pq: PriorityQueue) -> Cavern {
  let stop_if_finished = fn(cavern: Cavern, pq, fun) -> Cavern {
    case pq_is_empty(pq) {
      True -> cavern
      False -> fun()
    }
  }
  use <- stop_if_finished(cavern, pq)

  assert Ok(#(pq_item, pq)) = pq_get(pq)

  let update_cell_if_less_cost = fn(
    cavern: Cavern,
    pq,
    pq_item: PriorityQueueItem,
    fun,
  ) -> Cavern {
    assert Ok(current_cell) = map.get(cavern.cells, pq_item.coord)
    case
      pq_item.running_cost + current_cell.risk_level < current_cell.min_cost
    {
      True ->
        fun(
          Cell(
            ..current_cell,
            min_cost: pq_item.running_cost + current_cell.risk_level,
            shortest_path: [pq_item.coord, ..pq_item.running_path],
          ),
        )
      False -> do_traverse(cavern, pq)
    }
  }
  use current_cell <- update_cell_if_less_cost(cavern, pq, pq_item)

  let cavern_cells =
    map.update(cavern.cells, pq_item.coord, fn(_) { current_cell })

  let new_pq =
    adjacent(pq_item.coord, cavern.dimensions)
    |> iterator.from_list
    |> iterator.filter(fn(coord) {
      case list.first(pq_item.running_path) {
        Ok(last_coord) -> coord != last_coord
        Error(Nil) -> True
      }
    })
    |> iterator.fold(
      pq,
      fn(memo, coord) {
        pq_put(
          memo,
          PriorityQueueItem(
            coord,
            pq_item.running_cost + current_cell.risk_level,
            [pq_item.coord, ..pq_item.running_path],
          ),
        )
      },
    )
  do_traverse(Cavern(..cavern, cells: cavern_cells), new_pq)
}

fn correct_free_first_cell(cavern: Cavern) -> Cavern {
  assert Ok(starting_cell) = map.get(cavern.cells, C(0, 0))
  Cavern(
    ..cavern,
    cells: map.map_values(
      cavern.cells,
      fn(_, cell) {
        Cell(..cell, min_cost: cell.min_cost - starting_cell.risk_level)
      },
    ),
  )
}

fn parse_input(input: String) -> Cavern {
  let xss =
    string.split(input, "\n")
    |> iterator.from_list
    |> iterator.filter(fn(line) { !string.is_empty(line) })
    |> iterator.index
    |> iterator.map(fn(idx_line) {
      let #(y, line) = idx_line
      string.split(line, "")
      |> iterator.from_list
      |> iterator.index
      |> iterator.map(fn(idx_n) {
        let #(x, n) = idx_n
        assert Ok(n) = int.parse(n)
        #(C(x, y), Cell(min_cost: 999, risk_level: n, shortest_path: []))
      })
      |> iterator.to_list
    })
    |> iterator.to_list
  assert Ok(first_line) = list.first(xss)
  Cavern(
    cells: map.from_list(list.flatten(xss)),
    dimensions: Dimensions(list.length(first_line), list.length(xss)),
  )
}

fn enlarge_cavern(cavern: Cavern, times times: Int) -> Cavern {
  let new_dimensions =
    Dimensions(x: cavern.dimensions.x * times, y: cavern.dimensions.y * times)
  let overflow_increase_risk_level = fn(init_risk_level: Int, times: Int) -> Int {
    iterator.range(1, times)
    |> iterator.filter(fn(n) { n != 1 })
    |> iterator.fold(
      init_risk_level,
      fn(risk_level, _) {
        case risk_level {
          9 -> 1
          n -> n + 1
        }
      },
    )
  }

  let pair_it = {
    use y <- iterator.flat_map(iterator.range(0, new_dimensions.y - 1))
    use x <- iterator.map(iterator.range(0, new_dimensions.x - 1))

    let coord = C(x, y)
    let source_x = coord.x % cavern.dimensions.x
    let source_y = coord.y % cavern.dimensions.y
    assert Ok(source_cell) = map.get(cavern.cells, C(source_x, source_y))
    let quotient =
      1 + coord.x / cavern.dimensions.x + coord.y / cavern.dimensions.y
    #(
      coord,
      Cell(
        ..source_cell,
        risk_level: overflow_increase_risk_level(
          source_cell.risk_level,
          quotient,
        ),
      ),
    )
  }

  use memo, pair <- iterator.fold(pair_it, cavern)

  let #(coord, cell) = pair
  Cavern(dimensions: new_dimensions, cells: map.insert(memo.cells, coord, cell))
}

fn adjacent(to coord: Coordinate, inside dims: Dimensions) -> List(Coordinate) {
  let possibly_adjacent = [
    C(coord.x, coord.y - 1),
    C(coord.x + 1, coord.y),
    C(coord.x, coord.y + 1),
    C(coord.x - 1, coord.y),
  ]
  list.filter_map(
    possibly_adjacent,
    fn(coord) {
      case
        coord.x >= 0 && coord.y >= 0 && coord.x < dims.x && coord.y < dims.y
      {
        True -> Ok(coord)
        False -> Error(coord)
      }
    },
  )
}

fn pq_put(pq: PriorityQueue, item: PriorityQueueItem) -> PriorityQueue {
  PriorityQueue(items: [item, ..pq.items], sorted: False)
}

fn pq_get(pq: PriorityQueue) -> Result(#(PriorityQueueItem, PriorityQueue), Nil) {
  let sorted_items = case pq.sorted {
    True -> pq.items
    False ->
      list.sort(
        pq.items,
        fn(a, b) { int.compare(a.running_cost, b.running_cost) },
      )
  }

  case sorted_items {
    [] -> Error(Nil)
    [item] -> Ok(#(item, PriorityQueue(items: [], sorted: True)))
    [item, ..rest] -> Ok(#(item, PriorityQueue(items: rest, sorted: True)))
  }
}

fn pq_is_empty(pq: PriorityQueue) -> Bool {
  case pq.items {
    [] -> True
    _ -> False
  }
}

pub fn print_cavern(cavern: Cavern, cellfn: fn(Cell) -> String) -> Cavern {
  let pad_left = fn(s: String, length: Int) -> String {
    let s_length = string.length(s)
    case s_length >= length {
      True -> s
      False -> string.repeat(" ", length - s_length) <> s
    }
  }

  assert Ok(end_cell) =
    map.get(cavern.cells, C(cavern.dimensions.x - 1, cavern.dimensions.y - 1))
  iterator.range(0, cavern.dimensions.y - 1)
  |> iterator.map(fn(y) {
    iterator.range(0, cavern.dimensions.x - 1)
    |> iterator.map(fn(x) {
      assert Ok(cell) = map.get(cavern.cells, C(x, y))
      cellfn(cell)
      |> pad_left(1)
      |> fn(s) {
        case list.find(end_cell.shortest_path, fn(c) { c == C(x, y) }) {
          Ok(_) ->
            s
            |> shellout.style(with: shellout.color(["green"]), custom: [])
          Error(Nil) -> s
        }
      }
      |> io.print
    })
    |> iterator.run
    io.print("\n")
  })
  |> iterator.run
  cavern
}
