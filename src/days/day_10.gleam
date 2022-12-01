import gleam/string
import gleam/list
import gleam/int
import gleam/pair
import gleam/result
import gleam/iterator.{Iterator}

type Bracket {
  LRound
  LSquare
  LCurly
  LAngle
  RRound
  RSquare
  RCurly
  RAngle
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> find_syntax_errors()
  |> calculate_illegal_score()
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input()
  |> iterator.map(find_illegal_bracket)
  |> iterator.filter(result.is_ok)
  |> iterator.map(fn(ok_bracket) { result.unwrap(ok_bracket, []) })
  |> iterator.map(generate_completion)
  |> iterator.map(calculate_complete_score)
  |> find_middle()
}

fn parse_input(input: String) -> Iterator(List(Bracket)) {
  string.split(input, "\n")
  |> list.filter_map(fn(line) {
    case line {
      "" -> Error(Nil)
      line ->
        Ok(
          string.split(line, "")
          |> list.map(fn(bracket) {
            case bracket {
              "(" -> LRound
              ")" -> RRound
              "[" -> LSquare
              "]" -> RSquare
              "{" -> LCurly
              "}" -> RCurly
              "<" -> LAngle
              ">" -> RAngle
            }
          }),
        )
    }
  })
  |> iterator.from_list()
}

fn find_syntax_errors(
  bracket_lines: Iterator(List(Bracket)),
) -> Iterator(Bracket) {
  bracket_lines
  |> iterator.map(find_illegal_bracket)
  |> iterator.filter(result.is_error)
  |> iterator.map(fn(err_bracket) { result.unwrap_error(err_bracket, LRound) })
}

fn find_illegal_bracket(
  brackets: List(Bracket),
) -> Result(List(Bracket), Bracket) {
  list.try_fold(
    brackets,
    [],
    fn(memo, bracket) {
      let matches = fn(bracket: Bracket) -> Bool {
        case list.first(memo) {
          Error(Nil) -> False
          Ok(last_bracket) ->
            case last_bracket, bracket {
              LRound, RRound | LSquare, RSquare | LCurly, RCurly | LAngle, RAngle ->
                True
              _, _ -> False
            }
        }
      }
      case bracket {
        LRound | LSquare | LCurly | LAngle -> Ok([bracket, ..memo])
        _ ->
          case matches(bracket) {
            True ->
              case list.pop(memo, fn(_) { True }) {
                Ok(val) -> Ok(pair.second(val))
                Error(Nil) -> Error(bracket)
              }
            False -> Error(bracket)
          }
      }
    },
  )
}

fn calculate_illegal_score(illegal_brackets: Iterator(Bracket)) -> Int {
  illegal_brackets
  |> iterator.map(fn(bracket) {
    case bracket {
      RRound -> 3
      RSquare -> 57
      RCurly -> 1197
      RAngle -> 25137
      _ -> {
        assert True = False
        -1
      }
    }
  })
  |> iterator.fold(0, int.add)
}

fn generate_completion(incomplete_bracket_chunk: List(Bracket)) -> List(Bracket) {
  list.map(
    incomplete_bracket_chunk,
    fn(bracket) {
      case bracket {
        LRound -> RRound
        LSquare -> RSquare
        LCurly -> RCurly
        LAngle -> RAngle
        _ -> {
          assert True = False
          RRound
        }
      }
    },
  )
}

fn calculate_complete_score(completion_brackets: List(Bracket)) -> Int {
  list.fold(
    completion_brackets,
    0,
    fn(memo, bracket) {
      memo * 5 + case bracket {
        RRound -> 1
        RSquare -> 2
        RCurly -> 3
        RAngle -> 4
        _ -> -1
      }
    },
  )
}

fn find_middle(scores: Iterator(Int)) -> Int {
  let sorted =
    scores
    |> iterator.to_list()
    |> list.sort(int.compare)
  assert Ok(middle) = list.at(sorted, list.length(sorted) / 2)
  middle
}
