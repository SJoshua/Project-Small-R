import sys


def check_character(char):
    is_japanese = True
    is_simplified_chinese = True
    is_traditional_chinese = True

    # e.g. 草
    try:
        char.encode("SHIFT-JIS")
    except UnicodeEncodeError:
        is_japanese = False

    # e.g. 日本语
    try:
        char.encode("GB2312")
    except UnicodeEncodeError:
        is_simplified_chinese = False

    # e.g. 歷史
    try:
        char.encode("BIG5")
    except UnicodeEncodeError:
        is_traditional_chinese = False

    # if not is_japanese:
    #     print(f"{char}: JP[{is_japanese}] SC[{is_simplified_chinese}] TC[{is_traditional_chinese}]")

    return (is_simplified_chinese or is_traditional_chinese) and not is_japanese


def check_language(s: str):
    for char in s:
        if len(char.encode("UTF-8")) >= 2:
            if check_character(char):
                return True
    return False


# res = "".join(sys.argv)

print(check_language(open("text_tmp", "r").read()))