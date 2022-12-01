import gleam/list
import gleam/string
import gleam/int
import gleam/io
import gleam/iterator
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/erlang/process
import shellout

pub type Coordinate {
  C(x: Int, y: Int)
}

pub type Dimensions {
  Dimensions(x: Int, y: Int)
}

pub type Cell {
  Cell(risk_level: Int, last: Coordinate)
}

pub type Cells =
  Map(Coordinate, Cell)

pub type Cavern {
  Cavern(cells: Cells, dimensions: Dimensions)
}

type PriorityQueueItem {
  PriorityQueueItem(head: Coordinate, last_one: Coordinate, running_cost: Int)
}

type PriorityQueue {
  PriorityQueue(items: List(PriorityQueueItem))
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input
  |> traverse
  |> print_cavern([], fn(cell) { int.to_string(cell.risk_level) })
  todo
}

pub fn pt_2(input: String) -> Int {
  // input
  // |> parse_input
  // |> enlarge_cavern(times: 3)
  // |> traverse
  // |> print_cavern(fn(cell) { int.to_string(cell.risk_level) })
  // |> print_end_cell
  todo
}

fn end_coordinate(cavern: Cavern) -> Coordinate {
  C(cavern.dimensions.x - 1, cavern.dimensions.y - 1)
}

fn end_cell(cavern: Cavern) -> Cell {
  assert Ok(ending_cell) = map.get(cavern.cells, end_coordinate(cavern))
  ending_cell
}

fn print_end_cell(cavern: Cavern) -> Cavern {
  io.debug(end_cell(cavern))
  cavern
}

fn get_cell(cavern: Cavern, coordinate: Coordinate) -> Cell {
  assert Ok(cell) = map.get(cavern.cells, coordinate)
  cell
}

fn traverse(cavern: Cavern) -> Cavern {
  let pq =
    PriorityQueue(items: [
      PriorityQueueItem(head: C(0, 0), last_one: C(-1, -1), running_cost: 0),
    ])
  do_traverse(cavern, pq)
}

fn log_cavern(cavern: Cavern, pq: PriorityQueue) -> Nil {
  let highlights = case list.first(pq.items) {
    Ok(item) -> [item.head]
    Error(Nil) -> []
  }
  print_cavern(cavern, highlights, fn(cell) { int.to_string(cell.risk_level) })
  io.debug(highlights)
  // io.debug(pq.items)
  io.println("===============================")
  process.sleep(500)
  Nil
}

fn do_traverse(cavern: Cavern, pq: PriorityQueue) -> Cavern {
  log_cavern(cavern, pq)

  let crash_if_not_found = fn(pq: PriorityQueue, fun) -> Cavern {
    case pq_is_empty(pq) {
      False -> fun()
      True -> {
        assert True = False
        io.println("pq is empty")
        cavern
      }
    }
  }
  use <- crash_if_not_found(pq)

  assert Ok(#(pq_item, pq_items)) = list.pop(pq.items, fn(_) { True })
  let pq = PriorityQueue(items: pq_items)

  let update_last_in_cell = fn(
    cavern: Cavern,
    target: Coordinate,
    last: Coordinate,
  ) -> Cavern {
    Cavern(
      ..cavern,
      cells: map.update(
        cavern.cells,
        target,
        fn(cell) {
          assert Some(cell) = cell
          Cell(..cell, last: last)
        },
      ),
    )
  }

  let finish_if_goal_reached = fn(
    cavern: Cavern,
    pq_item: PriorityQueueItem,
    fun,
  ) -> Cavern {
    case pq_item.head == end_coordinate(cavern) {
      False -> fun()
      True -> update_last_in_cell(cavern, pq_item.head, pq_item.last_one)
    }
  }
  use <- finish_if_goal_reached(cavern, pq_item)

  let new_pq =
    adjacent(to: pq_item.head, inside: cavern.dimensions)
    |> list.filter(fn(coord) { coord != pq_item.last_one })
    |> list.fold(
      pq,
      fn(memo, adj) {
        let adj_cell = get_cell(cavern, adj)
        pq_put(
          memo,
          PriorityQueueItem(
            head: adj,
            last_one: pq_item.head,
            running_cost: pq_item.running_cost + adj_cell.risk_level,
          ),
        )
      },
    )
  let new_cavern = update_last_in_cell(cavern, pq_item.head, pq_item.last_one)

  do_traverse(new_cavern, new_pq)
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
        #(C(x, y), Cell(risk_level: n, last: C(-1, -1)))
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
  PriorityQueue(items: list.sort(
    [item, ..pq.items],
    fn(a, b) { int.compare(a.running_cost, b.running_cost) },
  ))
}

fn pq_get(pq: PriorityQueue) -> Result(#(PriorityQueueItem, PriorityQueue), Nil) {
  case pq.items {
    [] -> Error(Nil)
    [item] -> Ok(#(item, PriorityQueue(items: [])))
    [item, ..rest] -> Ok(#(item, PriorityQueue(items: rest)))
  }
}

fn pq_is_empty(pq: PriorityQueue) -> Bool {
  case pq.items {
    [] -> True
    _ -> False
  }
}

pub fn print_cavern(
  cavern: Cavern,
  shortest_path: List(Coordinate),
  cellfn: fn(Cell) -> String,
) -> Cavern {
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
        case list.find(shortest_path, fn(c) { c == C(x, y) }) {
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
