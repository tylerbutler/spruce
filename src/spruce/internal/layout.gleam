import gleam/string
import spruce.{type Spruce}

pub fn indent_prefix(sp: Spruce) -> String {
  string.repeat("  ", spruce.depth(sp))
}
