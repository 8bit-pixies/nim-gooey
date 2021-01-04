# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

include nim_gooey
test "longOption is set correctly":
  var outVar: ArgOpt = initArgOpt(key="hello")
  check outVar.key == "hello"
  check outVar.longOption == "hello"

test "default correctly overrides value":
  var outVar: ArgOpt = initArgOpt(key="hello", default=VariantType(kind:vkString, strValue:"hello"), typeName= vkString)
  check outVar.default.strValue == outVar.value.strValue
