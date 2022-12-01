import gleam/string
import gleam/list
import gleam/io
import gleam/int
import gleam/pair
import gleam/set.{Set}
import gleam/iterator

type Dot {
  Dot(x: Int, y: Int)
}

type Paper {
  Paper(dots: Set(Dot), dim_x: Int, dim_y: Int)
}

type Axis {
  X
  Y
}

type FoldInstruction {
  FoldInstruction(axis: Axis, value: Int)
}

pub fn pt_1(input: String) -> Int {
  let #(paper, fold_instructions) =
    input
    |> parse_input()
  assert Ok(first_instruction) = list.first(fold_instructions)
  paper
  |> fold_paper(first_instruction)
  |> count_dots()
}

pub fn pt_2(input: String) -> Int {
  let #(paper, fold_instructions) =
    input
    |> parse_input()
  list.fold(
    fold_instructions,
    paper,
    fn(paper, fold_instruction) { fold_paper(paper, fold_instruction) },
  )
  |> print_paper()
  0
}

fn fold_paper(paper: Paper, fold_instruction: FoldInstruction) -> Paper {
  case fold_instruction.axis {
    X -> {
      let dots =
        set.fold(
          paper.dots,
          set.new(),
          fn(memo, dot) {
            case dot.x < fold_instruction.value {
              True -> set.insert(memo, dot)
              False ->
                set.insert(
                  memo,
                  Dot(
                    x: fold_instruction.value - {
                      dot.x - fold_instruction.value
                    },
                    y: dot.y,
                  ),
                )
            }
          },
        )
      Paper(dots: dots, dim_x: fold_instruction.value, dim_y: paper.dim_y)
    }
    Y -> {
      let dots =
        set.fold(
          paper.dots,
          set.new(),
          fn(memo, dot) {
            case dot.y < fold_instruction.value {
              True -> set.insert(memo, dot)
              False ->
                set.insert(
                  memo,
                  Dot(
                    x: dot.x,
                    y: fold_instruction.value - {
                      dot.y - fold_instruction.value
                    },
                  ),
                )
            }
          },
        )
      Paper(dots: dots, dim_x: paper.dim_x, dim_y: fold_instruction.value)
    }
  }
}

fn count_dots(paper: Paper) -> Int {
  set.size(paper.dots)
}

type ParseLine {
  ParseLineFoldInstruction(axis: Axis, value: Int)
  ParseLineDot(x: Int, y: Int)
}

fn parse_input(input: String) -> #(Paper, List(FoldInstruction)) {
  let parse_coord = fn(x, y) -> ParseLine {
    assert Ok(x) = int.parse(x)
    assert Ok(y) = int.parse(y)
    ParseLineDot(x, y)
  }
  let parse_instruction = fn(instruction) -> ParseLine {
    assert [axis, value] = string.split(instruction, "=")
    assert Ok(value) = int.parse(value)
    let axis = case axis {
      "x" -> X
      "y" -> Y
    }
    ParseLineFoldInstruction(axis, value)
  }
  string.split(input, "\n")
  |> list.filter_map(fn(line) {
    case line {
      "fold along " <> instruction -> Ok(parse_instruction(instruction))
      _ ->
        case string.split(line, ",") {
          [x, y] -> Ok(parse_coord(x, y))
          _ -> Error(Nil)
        }
    }
  })
  |> list.fold(
    #(Paper(dots: set.new(), dim_x: -1, dim_y: -1), []),
    fn(memo, parse_line) {
      case parse_line {
        ParseLineFoldInstruction(axis, value) -> #(
          memo.0,
          [FoldInstruction(axis, value), ..memo.1],
        )
        ParseLineDot(x, y) -> {
          let paper = memo.0
          #(
            Paper(
              dots: set.insert(paper.dots, Dot(x, y)),
              dim_x: int.max(x + 1, paper.dim_x),
              dim_y: int.max(y + 1, paper.dim_y),
            ),
            memo.1,
          )
        }
      }
    },
  )
  |> pair.map_second(list.reverse)
}

fn print_paper(paper: Paper) -> Paper {
  io.println("Paper print:")
  iterator.range(0, paper.dim_y - 1)
  |> iterator.map(fn(row) {
    iterator.range(0, paper.dim_x - 1)
    |> iterator.map(fn(col) {
      let cell = case set.contains(paper.dots, Dot(col, row)) {
        True -> "#"
        False -> "."
      }
      io.print(cell)
    })
    |> iterator.run()
    io.print("\n")
  })
  |> iterator.run()

  paper
}
