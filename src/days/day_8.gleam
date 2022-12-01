import gleam/list
import gleam/string
import gleam/map
import gleam/set.{Set}
import gleam/int

type Segment {
  A
  B
  C
  D
  E
  F
  G
}

type SignalPattern =
  Set(Segment)

type Output =
  Set(Segment)

type Display {
  Display(signal_patterns: List(SignalPattern), outputs: List(Output))
}

type DigitMap =
  map.Map(Output, Int)

pub fn pt_1(input: String) -> Int {
  input
  |> parse_input()
  |> count_specific_outputs()
}

pub fn pt_2(input: String) -> Int {
  input
  |> parse_input()
  |> list.map(translate_outputs)
  |> int.sum()
}

fn parse_input(input: String) -> List(Display) {
  string.split(input, on: "\n")
  |> list.filter_map(fn(line) {
    case string.split(line, on: " | ") {
      [signal_patterns, outputs] -> {
        let parse_segments = fn(str: String) -> List(Set(Segment)) {
          string.split(str, on: " ")
          |> list.map(fn(segments) {
            string.split(segments, on: "")
            |> list.map(fn(segment) {
              case segment {
                "a" -> A
                "b" -> B
                "c" -> C
                "d" -> D
                "e" -> E
                "f" -> F
                "g" -> G
              }
            })
            |> set.from_list()
          })
        }
        Ok(Display(parse_segments(signal_patterns), parse_segments(outputs)))
      }
      _ -> Error(Nil)
    }
  })
}

fn count_specific_outputs(displays: List(Display)) -> Int {
  displays
  |> list.map(fn(display) { list.map(display.outputs, set.size) })
  |> list.flatten()
  |> list.filter(fn(length) {
    case length {
      2 | 4 | 3 | 7 -> True
      _ -> False
    }
  })
  |> list.length()
}

fn translate_outputs(display: Display) -> Int {
  let map = decipher(display.signal_patterns)
  display.outputs
  |> list.map(fn(output) {
    assert Ok(val) = map.get(map, output)
    val
  })
  |> int.undigits(10)
  |> force_unwrap()
}

fn decipher(signal_patterns: List(SignalPattern)) -> DigitMap {
  assert Ok(one) = list.find(signal_patterns, fn(pat) { set.size(pat) == 2 })
  assert Ok(seven) = list.find(signal_patterns, fn(pat) { set.size(pat) == 3 })
  assert Ok(four) = list.find(signal_patterns, fn(pat) { set.size(pat) == 4 })
  assert Ok(eight) = list.find(signal_patterns, fn(pat) { set.size(pat) == 7 })
  let two_three_five =
    list.filter(signal_patterns, fn(pat) { set.size(pat) == 5 })
  let zero_six_nine =
    list.filter(signal_patterns, fn(pat) { set.size(pat) == 6 })
  let three =
    list.filter(
      two_three_five,
      fn(pat) {
        set.intersection(of: pat, and: one)
        |> set.size == 2
      },
    )
    |> force_first()

  let middle_segment =
    set.intersection(of: three, and: four)
    |> set_difference(one)
    |> extract_single()
  let zero =
    list.filter(
      zero_six_nine,
      fn(pat) {
        set_difference(eight, pat)
        |> extract_single() == middle_segment
      },
    )
    |> force_first()
  let six =
    list.filter(
      zero_six_nine,
      fn(pat) {
        !set_equal(pat, zero) && set.size(set.intersection(pat, one)) == 1
      },
    )
    |> force_first()
  let nine =
    list.filter(
      zero_six_nine,
      fn(pat) { !set_equal(pat, zero) && !set_equal(pat, six) },
    )
    |> force_first()
  let five =
    list.filter(
      two_three_five,
      fn(pat) {
        !set_equal(pat, three) && set.size(set_difference(pat, nine)) == 0
      },
    )
    |> force_first()
  let two =
    list.filter(
      two_three_five,
      fn(pat) { !set_equal(pat, three) && !set_equal(pat, five) },
    )
    |> force_first()
  map.new()
  |> map.insert(for: zero, insert: 0)
  |> map.insert(for: one, insert: 1)
  |> map.insert(for: two, insert: 2)
  |> map.insert(for: three, insert: 3)
  |> map.insert(for: four, insert: 4)
  |> map.insert(for: five, insert: 5)
  |> map.insert(for: six, insert: 6)
  |> map.insert(for: seven, insert: 7)
  |> map.insert(for: eight, insert: 8)
  |> map.insert(for: nine, insert: 9)
}

fn set_difference(of first: Set(a), and second: Set(a)) -> Set(a) {
  set.fold(
    over: second,
    from: first,
    with: fn(memo, elem) { set.delete(from: memo, this: elem) },
  )
}

fn extract_single(set: Set(a)) -> a {
  set
  |> set.to_list()
  |> force_first()
}

fn force_first(xs: List(a)) -> a {
  assert 1 = list.length(xs)
  assert Ok(a) = list.first(xs)
  a
}

fn set_equal(first: Set(a), second: Set(a)) -> Bool {
  set.size(set.union(first, second)) == set.size(set.intersection(first, second))
}

fn force_unwrap(result: Result(a, b)) -> a {
  assert Ok(a) = result
  a
}
