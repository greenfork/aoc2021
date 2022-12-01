import gleam/string
import gleam/list
import gleam/map.{Map}
import gleam/regex
import gleam/io
import gleam/pair
import gleam/option.{None, Some}

pub type CaveId {
  Start
  End
  Small(String)
  Large(String)
}

type PassageMap =
  List(#(CaveId, CaveId))

type Cave {
  Cave(id: CaveId, visits: Int)
}

type Caves =
  Map(CaveId, Cave)

type Path =
  List(CaveId)

pub fn pt_1(input: String) -> Int {
  let #(passage_map, caves) =
    input
    |> parse_input()
  traverse(caves, passage_map, False)
  |> list.length()
}

pub fn pt_2(input: String) -> Int {
  let #(passage_map, caves) =
    input
    |> parse_input()
  traverse(caves, passage_map, True)
  |> list.length()
}

fn parse_input(input: String) -> #(PassageMap, Caves) {
  assert Ok(small_letters_reg) = regex.from_string("[a-z]+")
  assert Ok(capital_letters_reg) = regex.from_string("[A-Z]+")
  let passage_map =
    string.split(input, "\n")
    |> list.filter_map(fn(line) {
      case line {
        "" -> Error(Nil)
        line -> {
          assert [cave1, cave2] = string.split(line, "-")
          let string_to_cave = fn(cave: String) -> CaveId {
            case cave {
              "start" -> Start
              "end" -> End
              cave ->
                case regex.check(small_letters_reg, cave) {
                  True -> Small(cave)
                  False ->
                    case regex.check(capital_letters_reg, cave) {
                      True -> Large(cave)
                      False -> {
                        assert True = False
                        Start
                      }
                    }
                }
            }
          }
          Ok(#(string_to_cave(cave1), string_to_cave(cave2)))
        }
      }
    })
  let caves =
    list.fold(passage_map, [], fn(memo, pair) { [pair.0, pair.1, ..memo] })
    |> list.unique()
    |> list.map(fn(cave_id) { #(cave_id, Cave(id: cave_id, visits: 0)) })
    |> map.from_list()
  let passage_map =
    list.fold(
      passage_map,
      passage_map,
      fn(memo, pair) { [pair.swap(pair), ..memo] },
    )
    |> list.filter(fn(pair) {
      case pair.1 {
        Start -> False
        _ -> True
      }
    })
  #(passage_map, caves)
}

fn adjacent(passage_map: PassageMap, cave_id: CaveId) -> List(CaveId) {
  list.filter(
    passage_map,
    fn(pair) {
      case cave_id, pair.0 {
        Start, Start -> True
        End, End -> True
        Small(a), Small(b) if a == b -> True
        Large(a), Large(b) if a == b -> True
        _, _ -> False
      }
    },
  )
  |> list.map(pair.second)
}

fn traverse(
  caves: Caves,
  passage_map: PassageMap,
  can_visit_small_twice: Bool,
) -> List(Path) {
  do_traverse(caves, passage_map, [Start], !can_visit_small_twice)
}

fn do_traverse(
  caves: Caves,
  passage_map: PassageMap,
  path: Path,
  visited_small_twice: Bool,
) -> List(Path) {
  assert Ok(starting) = list.first(path)
  case starting {
    End -> [path]
    _ -> {
      let caves =
        map.update(
          caves,
          starting,
          fn(cave) {
            case cave {
              Some(cave) -> Cave(..cave, visits: cave.visits + 1)
              None -> {
                assert True = False
                Cave(Start, -1)
              }
            }
          },
        )
      adjacent(passage_map, starting)
      |> list.filter_map(fn(cave_id) {
        case cave_id {
          End | Large(_) ->
            Ok(do_traverse(
              caves,
              passage_map,
              [cave_id, ..path],
              visited_small_twice,
            ))
          Small(_) -> {
            assert Ok(cave) = map.get(caves, cave_id)
            case cave.visits {
              0 ->
                Ok(do_traverse(
                  caves,
                  passage_map,
                  [cave_id, ..path],
                  visited_small_twice,
                ))
              1 if visited_small_twice == False ->
                Ok(do_traverse(caves, passage_map, [cave_id, ..path], True))
              _ -> Error(Nil)
            }
          }
          _ -> {
            assert True = False
            Error(Nil)
          }
        }
      })
      |> list.flatten()
    }
  }
}

pub fn print_path(path: Path) -> Path {
  list.reverse(path)
  |> list.map(fn(cave_id) {
    case cave_id {
      Start -> "start"
      End -> "end"
      Small(a) -> a
      Large(a) -> a
    }
  })
  |> string.join(",")
  |> io.println()
  path
}
