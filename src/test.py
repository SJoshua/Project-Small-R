import sys


def check_character(char):
    is_japanese = True
    is_chinese = True

    try:
        char.encode("SHIFT-JIS")
    except UnicodeEncodeError:
        is_japanese = False

    try:
        char.encode("GB2312")
    except UnicodeEncodeError:
        is_chinese = False

    return is_chinese and not is_japanese


def check_language(s: str):
    for char in s:
        if len(char.encode("UTF-8")) >= 2:
            if check_character(char):
                return True
    return False

res = open('text_tmp', 'r').read()
print(check_language(res))
