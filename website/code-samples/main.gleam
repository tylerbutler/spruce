import gleam/io
import spruce
import spruce/box
import spruce/message
import spruce/output

pub fn main() {
  let context = spruce.detect()
  let rendered =
    output.new(context)
    |> output.append(box.simple(_, "spruce"))
    |> output.append(message.success(_, "ready"))
    |> output.to_string

  io.println(rendered)
}
