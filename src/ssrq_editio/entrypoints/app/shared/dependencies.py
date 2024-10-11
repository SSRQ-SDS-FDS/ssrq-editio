from typing import Annotated
from fastapi import Depends, Header, Query
from ssrq_editio.models.lang import Lang

__all__ = ["LangDependency"]


async def get_lang(
    x_lang: Annotated[str | None, Header()] = None, lang: Annotated[str | None, Query()] = None
) -> Lang:
    if x_lang:
        return Lang.from_string(x_lang)
    if lang:
        return Lang.from_string(lang)
    return Lang.DE


LangDependency = Annotated[Lang, Depends(get_lang)]
