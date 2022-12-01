import gleam/list
import gleam/string
import gleam/int
import gleam/float

pub fn pt_1(input: String) -> Int {
  let list =
    input
    |> parse_input()
  let medians = median(list)
  choose_difference(list, medians)
}

pub fn pt_2(input: String) -> Int {
  let list =
    input
    |> parse_input()
  let means = mean(list)
  choose_difference_cumulative(list, means)
}

fn parse_input(input: String) -> List(Int) {
  string.split(input, on: ",")
  |> list.filter_map(fn(n) { int.parse(n) })
}

fn mean(xs: List(Int)) -> #(Int, Int) {
  let sum =
    int.sum(xs)
    |> int.to_float()
  let length =
    list.length(xs)
    |> int.to_float()
  let mean = sum /. length
  #(float.round(float.floor(mean)), float.round(float.ceiling(mean)))
}

fn median(xs: List(Int)) -> #(Int, Int) {
  let sorted_xs = list.sort(xs, by: int.compare)
  let length = list.length(xs)
  case int.is_even(length) {
    False -> {
      assert Ok(median) = list.at(sorted_xs, length / 2 + 1)
      #(median, median)
    }
    True -> {
      assert Ok(median1) = list.at(sorted_xs, length / 2 - 1)
      assert Ok(median2) = list.at(sorted_xs, length / 2)
      #(median1, median2)
    }
  }
}

fn choose_difference(xs: List(Int), differences: #(Int, Int)) -> Int {
  let #(a, b) = differences
  let a_sum = difference_sum(xs, a)
  let b_sum = difference_sum(xs, b)
  case a_sum > b_sum {
    True -> b_sum
    False -> a_sum
  }
}

fn difference_sum(xs: List(Int), value: Int) -> Int {
  list.fold(xs, 0, fn(memo, x) { memo + int.absolute_value(value - x) })
}

fn choose_difference_cumulative(xs: List(Int), differences: #(Int, Int)) -> Int {
  let #(a, b) = differences
  let a_sum = difference_sum_cumulative(xs, a)
  let b_sum = difference_sum_cumulative(xs, b)
  case a_sum > b_sum {
    True -> b_sum
    False -> a_sum
  }
}

fn difference_sum_cumulative(xs: List(Int), value: Int) -> Int {
  list.fold(
    xs,
    0,
    fn(memo, x) {
      let abs = int.absolute_value(value - x)
      memo + int.sum(list.range(1, abs))
    },
  )
}
