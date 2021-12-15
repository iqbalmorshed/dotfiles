from collections.abc import Iterable, Iterator
from typing import Any

from pygments.filter import Filter
from pygments.lexer import Lexer
from pygments.token import _TokenType

def find_filter_class(filtername): ...
def get_filter_by_name(filtername, **options): ...
def get_all_filters(): ...

class CodeTagFilter(Filter):
    tag_re: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class SymbolFilter(Filter):
    latex_symbols: Any
    isabelle_symbols: Any
    lang_map: Any
    symbols: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class KeywordCaseFilter(Filter):
    convert: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class NameHighlightFilter(Filter):
    names: Any
    tokentype: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class ErrorToken(Exception): ...

class RaiseOnErrorTokenFilter(Filter):
    exception: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class VisibleWhitespaceFilter(Filter):
    wstt: Any
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class GobbleFilter(Filter):
    n: Any
    def __init__(self, **options) -> None: ...
    def gobble(self, value, left): ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

class TokenMergeFilter(Filter):
    def __init__(self, **options) -> None: ...
    def filter(self, lexer: Lexer, stream: Iterable[tuple[_TokenType, str]]) -> Iterator[tuple[_TokenType, str]]: ...

FILTERS: Any
