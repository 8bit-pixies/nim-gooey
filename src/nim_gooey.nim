# nim_gooey, attempts to replicate the behavior within Python argparse and also in Python/Gooey library

import parseopt
import tables
import strutils

# variable can take multiple result size
# see here: https://forum.nim-lang.org/t/2799
type
  VariantKind = enum
    vkBool
    vkString
    vkInt
    vkFloat
    vkSeqString
    vkSeqInt
    vkSeqFloat
    vkNil

  VariantType = object
    case kind: VariantKind
    of vkBool:
      boolValue: bool
    of vkString:
      strValue: string
    of vkInt:
      intValue: int
    of vkFloat:
      floatValue: float
    of vkSeqString:
      seqString: seq[string]
    of vkSeqInt:
      seqInt: seq[int]
    of vkSeqFloat:
      seqFloat: seq[float]
    of vkNil:
      nilValue: string

  ArgOpt = object
    key: string
    value: VariantType
    longOption: string
    shortOption: string
    default: VariantType
    action: string
    typeName: VariantKind

proc initArgOpt(key: string = "", value: VariantType = VariantType(kind: vkNil,
    nilValue: ""), longOption: string = "", shortOption: string = "",
    default: VariantType = VariantType(kind: vkNil, nilValue: ""),
    action: string = "store", typeName: VariantKind = vkNil): ArgOpt =
  result.key = key
  if value.kind == vkNil:
    result.value = default
  else:
    result.value = value

  result.action = action
  if action == "store_false":
    result.default = VariantType(kind: vkBool, boolValue: true)
  elif action == "store_true":
    result.default = VariantType(kind: vkBool, boolValue: false)

  if result.default.kind == vkNil and typeName == vkSeqString:
    result.default = VariantType(kind: vkSeqString, seqString: @[])
  elif result.default.kind == vkNil and typeName == vkSeqInt:
    result.default = VariantType(kind: vkSeqInt, seqInt: @[])
  elif result.default.kind == vkNil and typeName == vkSeqFloat:
    result.default = VariantType(kind: vkSeqFloat, seqFloat: @[])
  else:
    result.default = default



  if longOption == "":
    result.longOption = key
  else:
    result.longOption = longOption

  result.shortOption = shortOption
  result.typeName = typeName
  if default.kind != vkNil:
    assert default.kind == typeName

# https://nim-lang.org/docs/parseopt.html
# "-f --var:myName --type 1 --input file1.txt file2.txt"
var parseBuilder = @[
  initArgOpt(key = "f", default = VariantType(kind: vkBool, boolValue: false),
      action = "store_true", typeName = vkBool),
  initArgOpt(key = "var", default = VariantType(kind: vkString, strValue: ""),
      typeName = vkString),
  initArgOpt(key = "type", typeName = vkInt),
  initArgOpt(key = "input", typeName = vkSeqString),
]
var parseTable = initTable[string, ArgOpt]()

for val in parseBuilder:
  parseTable[val.key] = val


proc updateArgOptValue(argOpt: ArgOpt, value: string): VariantType =
  let typeName = argOpt.typeName
  result = argOpt.value
  echo "value is ", value
  case typeName:
  of vkBool:
    result = VariantType(kind: typeName,
        boolValue: not argOpt.default.boolValue)
  of vkString:
    result = VariantType(kind: typeName, strValue: value)
  of vkInt:
    result = VariantType(kind: typeName, intValue: parseInt(value))
  of vkFloat:
    result = VariantType(kind: typeName, floatValue: parseFloat(value))
  of vkNil:
    result = VariantType(kind: typeName, nilValue: "")
  of vkSeqString:
    if result.kind == vkNil or result.seqString.len() == 0:
      result = VariantType(kind: typeName, seqString: @[value])
    else:
      result.seqString.add(value)
  of vkSeqInt:
    if result.kind == vkNil or result.seqInt.len() == 0:
      result = VariantType(kind: typeName, seqInt: @[parseInt(value)])
    else:
      result.seqInt.add(parseInt(value))
  of vkSeqFloat:
    if result.kind == vkNil or result.seqFloat.len() == 0:
      result = VariantType(kind: typeName, seqFloat: @[parseFloat(value)])
    else:
      result.seqFloat.add(parseFloat(value))

type NoKeyException = object of Exception


var p = initOptParser("-f --var:myName --type 1 --input file1.txt file2.txt")
var currentKey: string
var pval: string
while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdLongOption, cmdShortOption:
    # todo check parseTable for both long and short option
    currentKey = p.key
    if not parseTable.hasKey(currentKey):
      # find the equivalent long key
      var notFound = true
      for k, v in pairs(parseTable):
        # echo k, " ", $v.value
        if v.shortOption == currentKey or v.longOption == currentkey:
          currentKey = v.key
          notFound = false
          break
      if notFound:
        raise NoKeyException.newException("Key: " & currentKey & " not found in parse definition!")

    if p.val == "":
      echo "currentkey is ", currentKey
      if parseTable[currentKey].typeName == vkBool:
        parseTable[currentKey].value = updateArgOptValue(parseTable[currentKey], "")
      echo "parseTable ", $parseTable[currentKey]
    else:
      pval = p.val
      echo "currentKey is ", currentKey, ", assigning value ", pval
      parseTable[currentKey].value = updateArgOptValue(parseTable[currentKey], pval)
      echo "parseTable ", $parseTable[currentKey]
  of cmdArgument:
    pval = p.key
    echo "currentKey is ", currentKey, ", assigning value ", pval
    parseTable[currentKey].value = updateArgOptValue(parseTable[currentKey], pval)
    echo "parseTable ", $parseTable[currentKey]

echo "\n\n"
echo "-f --var:myName --type 1 --input file1.txt file2.txt"
echo "----"
for k, v in pairs(parseTable):
  echo k, " ", $v.value
