import gleam/io
import gleam/option.{None, Option, Some}
import gleam/list
import gleam/int
import gleam/string
import gleam/iterator
import gleam/map
import gleam/result

type Lanternfish {
  Lanternfish(timer: Int)
}

fn live_day(lanternfish: Lanternfish) -> #(Lanternfish, Option(Lanternfish)) {
  case lanternfish {
    Lanternfish(0) -> #(Lanternfish(6), Some(Lanternfish(8)))
    Lanternfish(timer) -> #(Lanternfish(timer - 1), None)
  }
}

type School =
  map.Map(Lanternfish, Int)

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> simulate_slow(80)
  |> list.length()
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input()
  |> simulate_fast(256)
  |> io.debug()
  |> map.values()
  |> int.sum()
}

fn parse_input(input: String) -> List(Lanternfish) {
  input
  |> string.split(on: ",")
  |> list.filter_map(fn(num) {
    case num {
      "" -> Error(Nil)
      _ -> {
        assert Ok(n) = int.parse(num)
        Ok(Lanternfish(n))
      }
    }
  })
}

fn simulate_slow(fishes: List(Lanternfish), days: Int) -> List(Lanternfish) {
  iterator.iterate(from: fishes, with: simulate_single_day)
  |> iterator.drop(days)
  |> iterator.take(1)
  |> iterator.to_list()
  |> fn(xss) {
    assert Ok(xs) = list.first(xss)
    xs
  }
}

fn simulate_single_day(fishes: List(Lanternfish)) -> List(Lanternfish) {
  list.fold(
    over: fishes,
    from: [],
    with: fn(memo, fish) {
      case live_day(fish) {
        #(one, Some(another)) -> [one, another, ..memo]
        #(one, None) -> [one, ..memo]
      }
    },
  )
}

fn simulate_fast(fishes: List(Lanternfish), days: Int) -> School {
  let initial_school =
    list.fold(
      over: fishes,
      from: map.new(),
      with: fn(memo, fish) {
        map.update(
          in: memo,
          update: fish,
          with: fn(count) {
            case count {
              Some(i) -> i + 1
              None -> 1
            }
          },
        )
      },
    )
  iterator.iterate(from: initial_school, with: simulate_single_day_fast)
  |> iterator.drop(days)
  |> iterator.first()
  |> result.unwrap(map.new())
}

fn simulate_single_day_fast(school: School) -> School {
  map.keys(school)
  |> list.fold(
    from: map.new(),
    with: fn(memo, fish) {
      let current_number =
        map.get(school, fish)
        |> result.unwrap(0)
      let upd = fn(val) {
        case val {
          Some(i) -> i + current_number
          None -> current_number
        }
      }
      case fish {
        Lanternfish(0) ->
          map.update(memo, Lanternfish(6), upd)
          |> map.update(Lanternfish(8), upd)
        Lanternfish(timer) -> map.update(memo, Lanternfish(timer - 1), upd)
      }
    },
  )
}
