import gleam/map
import gleam/list
import gleam/int
import gleam/string
import gleam/option.{None, Some}

type Point {
  Point(x: Int, y: Int)
}

type LineSegment {
  LineSegment(p1: Point, p2: Point)
}

type WorldMap =
  map.Map(Point, Int)

type ScanMode {
  Straight
  Diagonal
}

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> put_on_world_map(Straight)
  |> calculate_overlapping_number_of_points()
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input()
  |> put_on_world_map(Diagonal)
  |> calculate_overlapping_number_of_points()
}

fn parse_input(input: String) -> List(LineSegment) {
  string.split(input, "\n")
  |> list.filter_map(fn(line) {
    case string.split(line, on: " -> ") {
      [p1, p2] -> {
        assert [x1, y1] = string.split(p1, on: ",")
        assert [x2, y2] = string.split(p2, on: ",")
        assert Ok(x1) = int.parse(x1)
        assert Ok(x2) = int.parse(x2)
        assert Ok(y1) = int.parse(y1)
        assert Ok(y2) = int.parse(y2)
        Ok(LineSegment(Point(x1, y1), Point(x2, y2)))
      }
      _ -> Error(Nil)
    }
  })
}

fn put_on_world_map(
  line_segments: List(LineSegment),
  scan_mode: ScanMode,
) -> WorldMap {
  list.fold(
    over: line_segments,
    from: map.new(),
    with: fn(memo, line_segment) {
      let points_from_line_segment = case scan_mode {
        Straight -> points_from_straight_line_segment(line_segment)
        Diagonal -> points_from_line_segment(line_segment)
      }
      list.fold(
        over: points_from_line_segment,
        from: memo,
        with: fn(memo, point) {
          map.update(
            in: memo,
            update: point,
            with: fn(val) {
              case val {
                Some(i) -> i + 1
                None -> 1
              }
            },
          )
        },
      )
    },
  )
}

fn points_from_straight_line_segment(line_segment: LineSegment) -> List(Point) {
  let check_straight_line_segment = fn(ls, fun) {
    let is_straight = fn(ls: LineSegment) {
      ls.p1.x == ls.p2.x || ls.p1.y == ls.p2.y
    }
    case is_straight(ls) {
      True -> fun()
      False -> []
    }
  }
  use <- check_straight_line_segment(line_segment)

  case line_segment.p1.x == line_segment.p2.x {
    True ->
      list.range(from: line_segment.p1.y, to: line_segment.p2.y)
      |> list.map(fn(y) { Point(line_segment.p1.x, y) })
    False ->
      list.range(from: line_segment.p1.x, to: line_segment.p2.x)
      |> list.map(fn(x) { Point(x, line_segment.p1.y) })
  }
}

fn points_from_line_segment(line_segment: LineSegment) -> List(Point) {
  case line_segment.p1.x == line_segment.p2.x {
    True ->
      list.range(from: line_segment.p1.y, to: line_segment.p2.y)
      |> list.map(fn(y) { Point(line_segment.p1.x, y) })
    False ->
      case line_segment.p1.y == line_segment.p2.y {
        True ->
          list.range(from: line_segment.p1.x, to: line_segment.p2.x)
          |> list.map(fn(x) { Point(x, line_segment.p1.y) })
        False ->
          list.range(from: line_segment.p1.x, to: line_segment.p2.x)
          |> list.zip(list.range(from: line_segment.p1.y, to: line_segment.p2.y))
          |> list.map(fn(dbl) { Point(dbl.0, dbl.1) })
      }
  }
}

fn calculate_overlapping_number_of_points(world_map: WorldMap) -> Int {
  map.fold(
    over: world_map,
    from: 0,
    with: fn(memo, _key, value) {
      case value > 1 {
        True -> memo + 1
        False -> memo
      }
    },
  )
}
