import gleam/string
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/option.{None, Some}
import gleam/int
import gleam/iterator.{Done, Iterator, Next}

type Polymer =
  List(String)

type PairMap =
  Map(#(String, String), Int)

type PolymerInfo {
  PolymerInfo(pair_map: PairMap, on_sides: #(String, String))
}

type Rules =
  Map(#(String, String), String)

pub fn pt_1(input: String) -> Int {
  let #(polymer, rules) =
    input
    |> parse_input()
  polymer
  |> iterator.iterate(fn(polymer) { polymerize(polymer, rules) })
  |> iterator.drop(10)
  |> iterator.first()
  |> result.unwrap([])
  |> iterator.from_list()
  |> iterator.group(fn(ch) { ch })
  |> map.map_values(fn(_, frequency) { list.length(frequency) })
  |> map.to_list()
  |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
  |> min_max_difference()
}

pub fn pt_2(input: String) -> Int {
  let #(polymer, rules) =
    input
    |> parse_input()
  let polymer_info = into_polymer_info(polymer)
  polymer_info
  |> iterator.iterate(fn(polymer_info) { polymerize_fast(polymer_info, rules) })
  |> iterator.drop(40)
  |> iterator.first()
  |> result.unwrap(PolymerInfo(map.new(), #("oh", "no")))
  |> count_monomer_occurrences()
  |> map.to_list()
  |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
  |> min_max_difference()
}

fn polymerize_fast(polymer_info: PolymerInfo, rules: Rules) -> PolymerInfo {
  let pair_map =
    map.fold(
      polymer_info.pair_map,
      map.new(),
      fn(memo, pair, count) {
        let check_zero_count = fn(count, fun) {
          case count {
            0 -> memo
            _ -> fun()
          }
        }
        use <- check_zero_count(count)

        case map.get(rules, pair) {
          Ok(insertion) ->
            map.update(
              memo,
              #(pair.0, insertion),
              fn(cnt) {
                case cnt {
                  Some(i) -> i + count
                  None -> count
                }
              },
            )
            |> map.update(
              #(insertion, pair.1),
              fn(cnt) {
                case cnt {
                  Some(i) -> i + count
                  None -> count
                }
              },
            )
          Error(Nil) ->
            map.update(
              memo,
              pair,
              fn(cnt) {
                case cnt {
                  Some(_) -> {
                    assert True = False
                    -1
                  }
                  None -> count
                }
              },
            )
        }
      },
    )
  PolymerInfo(..polymer_info, pair_map: pair_map)
}

fn count_monomer_occurrences(polymer_info: PolymerInfo) -> Map(String, Int) {
  map.fold(
    polymer_info.pair_map,
    map.new(),
    fn(memo, pair, count) {
      memo
      |> map.update(
        pair.0,
        fn(cnt) {
          case cnt {
            Some(i) -> i + count
            None -> count
          }
        },
      )
      |> map.update(
        pair.1,
        fn(cnt) {
          case cnt {
            Some(i) -> i + count
            None -> count
          }
        },
      )
    },
  )
  |> map.map_values(fn(monomer, count) {
    let on_sides = polymer_info.on_sides
    case monomer {
      _ if monomer == on_sides.0 || monomer == on_sides.1 -> count / 2 + 1
      _ -> count / 2
    }
  })
}

fn into_polymer_info(polymer: Polymer) -> PolymerInfo {
  assert Ok(leftmost) = list.first(polymer)
  assert Ok(rightmost) = list.last(polymer)
  let pair_map =
    window_by_2_iterator(polymer)
    |> iterator.fold(
      map.new(),
      fn(memo, pair) {
        let check_pair_none = fn(pair: #(String, String), fun) {
          case pair.0, pair.1 {
            "none", _ | _, "none" -> memo
            _, _ -> fun()
          }
        }
        use <- check_pair_none(pair)

        map.update(
          memo,
          pair,
          fn(count) {
            case count {
              Some(i) -> i + 1
              None -> 1
            }
          },
        )
      },
    )
  PolymerInfo(pair_map, on_sides: #(leftmost, rightmost))
}

fn window_by_2_iterator(xs: List(String)) -> Iterator(#(String, String)) {
  iterator.unfold(
    xs,
    fn(xs) {
      case xs {
        [] -> Done
        [a] -> Next(element: #(a, "none"), accumulator: [])
        [a, b] -> Next(element: #(a, b), accumulator: [b])
        [a, b, ..rest] -> Next(element: #(a, b), accumulator: [b, ..rest])
      }
    },
  )
}

fn polymerize(polymer: Polymer, rules: Rules) -> Polymer {
  window_by_2_iterator(polymer)
  |> iterator.fold(
    [],
    fn(memo, pair) {
      case map.get(rules, pair) {
        Ok(insertion) -> [insertion, pair.0, ..memo]
        Error(Nil) -> [pair.0, ..memo]
      }
    },
  )
  |> list.reverse()
}

fn min_max_difference(counts: List(#(String, Int))) -> Int {
  assert Ok(min) = list.first(counts)
  assert Ok(max) = list.last(counts)
  max.1 - min.1
}

fn parse_input(input: String) -> #(Polymer, Rules) {
  let lines = string.split(input, "\n")
  assert Ok(polymer) = list.first(lines)
  let polymer = string.split(polymer, "")
  let rules =
    lines
    |> list.drop(2)
    |> list.filter_map(fn(line) {
      case string.split(line, " -> ") {
        [from, to] -> {
          assert [a, b] = string.split(from, "")
          Ok(#(#(a, b), to))
        }
        _ -> Error(Nil)
      }
    })
    |> map.from_list()
  #(polymer, rules)
}
